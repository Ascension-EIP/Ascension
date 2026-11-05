# @date 2026-11-01
# @file test_coverage_gaps.py
# @brief Unit tests of decisions and error branches that no other test reaches (found with pytest-cov).
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
import json
from types import SimpleNamespace
from unittest.mock import MagicMock
from uuid import uuid4

import numpy as np
import pytest
from botocore.exceptions import ClientError, EndpointConnectionError
from pydantic import BaseModel, ValidationError

import producer
from common.db_schemas.analysis import Analysis
from common.utils.errors import PermanentError, throw_if_none, with_retry
from services import rabbitmq
from services.llm import LLM
from services.rabbitmq import DLX, Broker
from services.rustfs import RustFS
from shared.models import Job, PoseDetectRequest, RoutingKey, Status
from worker import cli
from worker._1_mediapipe.pose_geometry import angle
from worker.handlers import failure

RESULT = {"fps": 30.0, "width": 1080, "height": 1920, "frames": []}
HINTS = {
    "summary": "s",
    "items": [{"category": "technique", "priority": 9, "title": "t", "description": "d"}],
    "model": "m",
    "generated_at": "2026-09-18T10:12:00Z",
}


# --- row validation: the CHECK constraints must fail here, not in PostgreSQL --------------------


def test_success_needs_result_and_completion_time():
    with pytest.raises(ValidationError, match="requires both"):
        Analysis(video_id=uuid4(), status=Status.SUCCESS, result=RESULT)


def test_failed_needs_an_error():
    with pytest.raises(ValidationError, match="requires `error`"):
        Analysis(video_id=uuid4(), status=Status.FAILED)


def test_hint_priority_is_bounded():
    with pytest.raises(ValidationError, match="between 1 and 5"):
        Analysis(video_id=uuid4(), hints=HINTS)


# --- small helpers ------------------------------------------------------------------------------


def test_angle_of_a_zero_length_segment_is_undefined():
    a, b = np.array([0.0, 0.0]), np.array([1.0, 0.0])
    assert angle(a, a, b) is None
    assert angle(b, a, np.array([0.0, 1.0])) == pytest.approx(90.0)


def test_missing_config_field_is_reported():
    class Config(BaseModel):
        url: str | None = None

    with pytest.raises(ValueError, match="url"):
        throw_if_none(Config())


def test_with_retry_needs_at_least_one_attempt():
    with pytest.raises(ValueError, match="attempts"):
        with_retry(lambda: 1, attempts=0)


# --- LLM client ---------------------------------------------------------------------------------


def test_llm_client_never_retries_itself_and_accepts_no_key(monkeypatch):
    client = MagicMock()
    monkeypatch.setattr("services.llm.openai.OpenAI", client)
    monkeypatch.delenv("LLM_API_KEY", raising=False)
    LLM().setup_config("http://llm.test/v1", "m").connect()
    kwargs = client.call_args.kwargs
    assert kwargs["max_retries"] == 0 and kwargs["api_key"] == "EMPTY" and kwargs["base_url"] == "http://llm.test/v1"


def test_generate_json_connects_on_first_use(monkeypatch):
    client = MagicMock()
    client.return_value.chat.completions.create.return_value = SimpleNamespace(
        choices=[SimpleNamespace(message=SimpleNamespace(content='{"a": 1}'))]
    )
    monkeypatch.setattr("services.llm.openai.OpenAI", client)
    assert LLM().setup_config("http://llm.test/v1", "m").generate_json("hi") == {"a": 1}


# --- storage ------------------------------------------------------------------------------------


def test_missing_bucket_at_startup_is_permanent(monkeypatch):
    s3 = MagicMock()
    s3.head_bucket.side_effect = ClientError(
        {"Error": {"Code": "404"}, "ResponseMetadata": {"HTTPStatusCode": 404}}, "HeadBucket"
    )
    monkeypatch.setattr("services.rustfs.boto3.client", lambda *a, **k: s3)
    with pytest.raises(PermanentError):
        RustFS().setup_config().connect()


def test_unreachable_storage_at_startup_is_transient(monkeypatch):
    s3 = MagicMock()
    s3.head_bucket.side_effect = EndpointConnectionError(endpoint_url="http://x")
    monkeypatch.setattr("services.rustfs.boto3.client", lambda *a, **k: s3)
    with pytest.raises(Exception, match="unreachable") as e:
        RustFS().setup_config().connect()
    assert type(e.value).__name__ == "TransientError"


def test_storage_config_comes_from_the_environment(monkeypatch):
    monkeypatch.setenv("RUSTFS_ENDPOINT", "http://s3.test:9")
    monkeypatch.setenv("RUSTFS_BUCKET", "other")
    config = RustFS().setup_config().config
    assert (config.endpoint, config.bucket) == ("http://s3.test:9", "other")


# --- broker -------------------------------------------------------------------------------------


def make_broker() -> Broker:
    broker = Broker().setup_config()
    broker.channel, broker.connection = MagicMock(), MagicMock()
    return broker


def test_every_queue_gets_a_dead_letter_queue_bound_to_the_dlx():
    broker = make_broker().setup_channel()
    declared = {c.kwargs["queue"]: c.kwargs.get("arguments") for c in broker.channel.queue_declare.call_args_list}
    for queue in ("poses.detect", "poses.advice"):
        assert declared[queue] == {"x-dead-letter-exchange": DLX, "x-dead-letter-routing-key": f"{queue}.dlq"}
        assert declared[f"{queue}.dlq"] is None
        broker.channel.queue_bind.assert_any_call(queue=f"{queue}.dlq", exchange=DLX, routing_key=f"{queue}.dlq")
    broker.channel.basic_qos.assert_called_once_with(prefetch_count=1, global_qos=True)


def test_consumer_runs_one_job_at_a_time_and_stops_its_executor():
    broker = make_broker()
    broker.start_consuming()
    consumed = [c.kwargs["queue"] for c in broker.channel.basic_consume.call_args_list]
    assert sorted(consumed) == ["poses.advice", "poses.detect"]  # one consumer per queue, not per binding
    with pytest.raises(RuntimeError):  # the executor is shut down once consuming ends
        broker.submit(lambda: None)


def test_pika_calls_from_the_job_thread_are_handed_to_the_io_thread(monkeypatch):
    broker = make_broker()
    broker._io_thread = -1  # not the current thread
    broker.ack(5)
    broker.nack(6)
    broker.publish(RoutingKey.POSE_ADVICE_STATUS, Job(job_id="j"))
    assert broker.connection.add_callback_threadsafe.call_count == 3
    broker.channel.basic_ack.assert_not_called()  # nothing touches the channel from this thread
    for call in broker.connection.add_callback_threadsafe.call_args_list:
        call.args[0]()
    broker.channel.basic_ack.assert_called_once_with(delivery_tag=5)
    broker.channel.basic_nack.assert_called_once_with(delivery_tag=6, requeue=False)
    assert broker.channel.basic_publish.call_args.kwargs["routing_key"] == RoutingKey.POSE_ADVICE_STATUS


def test_pika_calls_before_consuming_run_directly():
    broker = make_broker()
    broker.publish(RoutingKey.POSE_DETECT_COMPLETED, Job(job_id="j"))
    broker.connection.add_callback_threadsafe.assert_not_called()
    assert b'"job_id":"j"' in broker.channel.basic_publish.call_args.kwargs["body"]


def test_connect_gives_up_after_the_configured_attempts(monkeypatch):
    monkeypatch.setenv("RABBITMQ_MAX_RETRIES", "2")
    monkeypatch.setenv("RABBITMQ_RETRY_DELAY", "0")
    monkeypatch.setattr(rabbitmq.pika, "BlockingConnection", MagicMock(side_effect=OSError("down")))
    with pytest.raises(Exception, match="after 2 attempts"):
        Broker().setup_config().connect()


# --- failure path -------------------------------------------------------------------------------


def test_failure_report_survives_a_broken_database_and_broker(monkeypatch):
    db, broker = MagicMock(), MagicMock()
    db.fail.side_effect = OSError("db down")
    broker.publish.side_effect = OSError("broker down")
    monkeypatch.setattr(failure, "get_db", lambda: db)
    monkeypatch.setattr(failure, "get_broker", lambda: broker)
    error = failure.fail_job("j", RoutingKey.POSE_DETECT_STATUS, "pose", ValueError("secret detail"))
    assert isinstance(error, PermanentError) and str(error) == "Analysis failed"  # still dead-lettered, no detail


# --- producer: messages are the generated types, sent through Broker.publish --------------------


@pytest.fixture
def sent(monkeypatch):
    broker = MagicMock()
    broker.setup_config.return_value.connect.return_value.setup_channel.return_value = broker
    monkeypatch.setattr(producer, "Broker", lambda: broker)
    return broker


def test_producer_detect_publishes_a_typed_request(sent):
    producer.main(["detect", "--job-id", "j", "--object-key", "k.mp4"])
    sent.publish.assert_called_once_with(
        RoutingKey.POSE_DETECT_REQUESTED, PoseDetectRequest(job_id="j", object_key="k.mp4")
    )
    sent.connection.close.assert_called_once()
    sent.channel.basic_publish.assert_not_called()


def test_producer_advice_publishes_a_job_and_closes_on_error(sent):
    sent.publish.side_effect = OSError("down")
    with pytest.raises(SystemExit) as e:
        producer.main(["advice", "--job-id", "j"])
    assert e.value.code == 1
    sent.publish.assert_called_once_with(RoutingKey.POSE_ADVICE_REQUESTED, Job(job_id="j"))
    sent.connection.close.assert_called_once()


def test_producer_needs_a_command():
    with pytest.raises(SystemExit) as e:
        producer.main([])
    assert e.value.code == 2


# --- CLI glue -----------------------------------------------------------------------------------


def test_consume_connects_every_service_before_it_blocks(monkeypatch):
    order = []
    db, storage = MagicMock(), MagicMock()
    db.connect.side_effect = lambda: order.append("db")
    storage.connect.side_effect = lambda: order.append("storage")
    broker = MagicMock()
    broker.setup_config.return_value.connect.return_value.setup_channel.return_value.start_consuming.side_effect = (
        lambda: order.append("consume")
    )
    monkeypatch.setattr("worker.runtime.get_db", lambda: db)
    monkeypatch.setattr("worker.runtime.get_storage", lambda: storage)
    monkeypatch.setattr("worker.runtime.get_broker", lambda: broker)
    cli.consume()
    assert order == ["db", "storage", "consume"]


def test_main_exits_non_zero_when_a_step_fails(monkeypatch):
    monkeypatch.setattr(cli, "consume", MagicMock(side_effect=PermanentError("bucket missing")))
    with pytest.raises(SystemExit) as e:
        cli.main([])
    assert e.value.code == 1


def test_main_stops_quietly_on_ctrl_c(monkeypatch):
    monkeypatch.setattr(cli, "consume", MagicMock(side_effect=KeyboardInterrupt))
    cli.main([])  # no SystemExit


def test_pose_advice_passes_cli_overrides_to_the_llm(tmp_path, monkeypatch):
    from tests.test_pose_advice import make_result

    seen = {}

    class FakeLLM:
        def __init__(self):
            self.config = SimpleNamespace(model="m")

        def setup_config(self, base_url, model):
            seen.update(base_url=base_url, model=model)
            return self

        def connect(self):
            return self

        def generate_json(self, prompt):
            return {"summary": "s", "items": []}

    monkeypatch.setattr("services.llm.LLM", FakeLLM)
    src, out = tmp_path / "in.json", tmp_path / "out.json"
    src.write_text(json.dumps(make_result(n=5)))
    cli.main(["pose-advice", "--input", str(src), "--out", str(out), "--base-url", "http://x/v1", "--model", "mm"])
    assert seen == {"base_url": "http://x/v1", "model": "mm"} and '"summary":"s"' in out.read_text()


# --- runtime ------------------------------------------------------------------------------------


def test_runtime_getters_share_one_instance_and_llm_needs_config(monkeypatch):
    from worker import runtime

    getters = [runtime.get_broker, runtime.get_db, runtime.get_storage, runtime.get_pose_skeleton]
    for g in getters:
        g.cache_clear()
        assert g() is g()  # one instance per process, built on first use
        g.cache_clear()
    for var in ("LLM_BASE_URL", "LLM_MODEL"):
        monkeypatch.delenv(var, raising=False)
    runtime.get_llm.cache_clear()
    with pytest.raises(ValueError, match="LLM_BASE_URL"):
        runtime.get_llm()  # a failure is not cached: the next call retries
    runtime.get_llm.cache_clear()
