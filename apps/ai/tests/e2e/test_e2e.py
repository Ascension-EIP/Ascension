# @date 2026-11-01
# @file test_e2e.py
# @brief End-to-end flow on the real RabbitMQ, PostgreSQL and RustFS (LLM faked).
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
import json
import tempfile
import time
from pathlib import Path
from uuid import uuid4

import pytest

import producer
from services.postgresql import PostgreSQL
from shared.models import AnalysisResult, Hints, Job, PoseDetectRequest, RoutingKey
from tests.e2e.conftest import FakeLLM, Observer, wait_until

pytestmark = [pytest.mark.e2e, pytest.mark.usefixtures("worker")]

ROW = "SELECT status, progress, result, error, completed_at, processing_time_ms FROM analyses WHERE id = %s"
ADVICE_ROW = "SELECT status, progress, result, error, completed_at, processing_time_ms FROM advices WHERE id = %s"
KEYS = ("status", "progress", "result", "error", "completed_at", "processing_time_ms")


def row(db: PostgreSQL, job_id: str, sql: str = ROW) -> dict:
    return dict(zip(KEYS, db.connection.execute(sql, (job_id,)).fetchone(), strict=True))


def advice_row(db: PostgreSQL, video_id: str) -> dict:
    return row(db, video_id, ADVICE_ROW)


def wait_for_end(db: PostgreSQL, job_id: str, sql: str = ROW) -> dict:
    ended = wait_until(lambda: row(db, job_id, sql) if row(db, job_id, sql)["status"] in ("success", "failed") else None)
    assert ended, f"job {job_id} did not end: {row(db, job_id, sql)}"
    return ended


def detect(job: producer.Seeded) -> None:
    producer.publish(RoutingKey.POSE_DETECT_REQUESTED, PoseDetectRequest(job_id=job.job_id, object_key=job.object_key))


def temp_videos() -> set[Path]:
    return set(Path(tempfile.gettempdir()).glob("tmp*.mp4"))


def test_nominal_flow(db, seeded, observer: Observer):
    FakeLLM.mode = "ok"
    job, before = seeded(), temp_videos()
    start = time.monotonic()
    detect(job)
    final = wait_for_end(db, job.job_id)
    wall = time.monotonic() - start

    assert final["status"] == "success" and final["error"] is None, final
    result = AnalysisResult.model_validate(final["result"])
    assert result.frames and result.metrics is not None and result.movements is not None
    assert final["progress"] == 100
    assert final["completed_at"] is not None and final["processing_time_ms"] is not None

    # Advice is a separate job, requested by the server (`POST /advices/:id`).
    assert advice_row(db, job.video_id)["status"] == "pending"
    producer.publish(RoutingKey.POSE_ADVICE_REQUESTED, Job(job_id=job.video_id))
    advice = wait_for_end(db, job.video_id, ADVICE_ROW)
    assert advice["status"] == "success" and advice["error"] is None and advice["progress"] == 100
    hints = Hints.model_validate(advice["result"])
    assert hints.items and hints.model == "fake-llm"
    assert advice["completed_at"] is not None and advice["processing_time_ms"] is not None
    assert observer.wait_status(job.video_id, RoutingKey.POSE_ADVICE_STATUS, "success")
    detect_statuses = observer.seen(job.job_id, RoutingKey.POSE_DETECT_STATUS)
    assert {"started", "running", "success"} <= set(detect_statuses)
    assert detect_statuses.index("started") < detect_statuses.index("running") < detect_statuses.index("success")
    assert temp_videos() == before, "a downloaded video was left in the temp directory"
    print(f"\nE2E example-2.mp4: {wall:.1f} s wall clock, processing_time_ms = {final['processing_time_ms']}")


def test_invalid_payload_goes_to_the_dead_letter_queue(observer: Observer):
    marker = str(uuid4())
    observer.publish_raw(RoutingKey.POSE_DETECT_REQUESTED, json.dumps({"job_id": marker}).encode())  # no object_key
    assert observer.take_dead_letter("poses.detect.dlq", marker)


def test_missing_object_fails_the_job_and_is_dead_lettered(db, seeded, observer: Observer):
    job = seeded()
    detect(job._replace(object_key=f"seed/absent-{uuid4().hex}.mp4"))
    final = wait_for_end(db, job.job_id)
    assert final["status"] == "failed" and final["result"] is None
    assert final["error"] and "Traceback" not in final["error"]
    assert observer.wait_status(job.job_id, RoutingKey.POSE_DETECT_STATUS, "failed")
    assert observer.take_dead_letter("poses.detect.dlq", job.job_id)


@pytest.fixture(scope="module")
def llm_down_job(db, seeded, observer: Observer):
    """A video whose analysis succeeded while the LLM was down for its advice."""
    FakeLLM.mode = "down"
    try:
        job = seeded()
        detect(job)
        wait_for_end(db, job.job_id)
        producer.publish(RoutingKey.POSE_ADVICE_REQUESTED, Job(job_id=job.video_id))
        final = wait_for_end(db, job.video_id, ADVICE_ROW)
        assert observer.wait_status(job.video_id, RoutingKey.POSE_ADVICE_STATUS, "failed", timeout=60)
    finally:
        FakeLLM.mode = "ok"
    return job, final


def test_llm_failure_fails_only_the_advice(db, llm_down_job, observer: Observer):
    job, final = llm_down_job
    assert final["status"] == "failed" and final["error"] and final["result"] is None
    analysis = row(db, job.job_id)
    assert analysis["status"] == "success" and analysis["result"] is not None  # the analysis is untouched
    assert "success" not in observer.seen(job.video_id, RoutingKey.POSE_ADVICE_STATUS)


def test_advice_retry_fills_the_result(db, llm_down_job, observer: Observer):
    job, _ = llm_down_job
    FakeLLM.mode = "ok"
    producer.publish(RoutingKey.POSE_ADVICE_REQUESTED, Job(job_id=job.video_id))
    assert wait_until(lambda: advice_row(db, job.video_id)["result"], timeout=60), "hints were not written"
    final = advice_row(db, job.video_id)
    assert Hints.model_validate(final["result"]).items
    assert final["status"] == "success" and final["progress"] == 100 and final["error"] is None
    assert observer.wait_status(job.video_id, RoutingKey.POSE_ADVICE_STATUS, "success")
