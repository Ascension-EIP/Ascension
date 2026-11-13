# @date 2026-11-01
# @file conftest.py
# @brief Fixtures of the end-to-end tests: infrastructure check, worker thread, fake LLM, seeded jobs.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""Fixtures of the end-to-end tests.

The real RabbitMQ, PostgreSQL and RustFS are used, configured by the same
variables as the worker (``POSTGRES_*``, ``RABBITMQ_*``, ``RUSTFS_*``).
``TEST_POSTGRES_URL`` overrides the database URL. The worker runs in a thread of
the test process; only the LLM is replaced, by patching ``services.llm.LLM``
(there is no fake mode in the production code).
"""

import json
import os
import threading
import time
import urllib.request
from collections.abc import Callable, Iterator
from pathlib import Path
from types import SimpleNamespace

import pika
import psycopg
import pytest
from dotenv import load_dotenv
from pika.exceptions import AMQPError

import producer
from common.utils.errors import PermanentError, TransientError
from services.postgresql import PostgreSQL
from services.rabbitmq import Broker
from services.rustfs import RustFS
from shared.models import RoutingKey

APP = Path(__file__).resolve().parents[2]

VIDEO = APP / "resources" / "example-2.mp4"
TIMEOUT_S = 240
GOOD_ANSWER = {
    "summary": "Bonne séance.",
    "items": [{"category": "technique", "priority": 2, "title": "Hanches", "description": "Rapproche les hanches du mur."}],
}
STATUS_KEYS = (RoutingKey.POSE_DETECT_STATUS, RoutingKey.POSE_ADVICE_STATUS)

load_dotenv()


class FakeLLM:
    """Replaces `services.llm.LLM`. ``mode`` is shared, so tests can switch it at any time."""

    mode = "ok"  # "ok" or "down"

    def __init__(self):
        self.config = SimpleNamespace(model="fake-llm")

    def setup_config(self, *args, **kwargs):
        return self

    def connect(self):
        return self

    def generate_json(self, prompt: str) -> dict:
        if FakeLLM.mode == "down":
            raise TransientError("LLM unreachable (fake)")
        return GOOD_ANSWER


def postgres_url() -> str:
    return (
        os.getenv("TEST_POSTGRES_URL")
        or os.getenv("POSTGRES_DB_URL")
        or "postgresql://{u}:{p}@{h}:{port}/{d}".format(
            u=os.getenv("POSTGRES_USER", "ascension"),
            p=os.getenv("POSTGRES_PASSWORD", "ascension"),
            h=os.getenv("POSTGRES_HOST", "localhost"),
            port=os.getenv("POSTGRES_PORT", "5432"),
            d=os.getenv("POSTGRES_DB", "ascension"),
        )
    )


def _amqp_params() -> pika.ConnectionParameters:
    config = Broker().setup_config().config
    return pika.ConnectionParameters(
        host=config.host,
        port=config.port,
        credentials=pika.PlainCredentials(config.user, config.password),
        connection_attempts=1,
        socket_timeout=3,
        blocked_connection_timeout=300,
    )


def _consumers(queue: str) -> int:
    """Number of consumers on ``queue`` (0 when it does not exist yet)."""
    with pika.BlockingConnection(_amqp_params()) as connection:
        try:
            return connection.channel().queue_declare(queue=queue, passive=True).method.consumer_count
        except pika.exceptions.ChannelClosedByBroker as e:
            if e.reply_code == 404:
                return 0
            raise


@pytest.fixture(scope="session")
def url() -> str:
    """The database URL; skips the e2e tests when an infrastructure service is unavailable."""
    url = postgres_url()
    try:
        with psycopg.connect(url, connect_timeout=3) as c:
            c.execute("SELECT hints FROM analyses LIMIT 0")
    except psycopg.errors.UndefinedColumn:
        pytest.skip("PostgreSQL: migrations not applied (moon run server:migrate)")
    except psycopg.Error as e:
        pytest.skip(f"PostgreSQL unreachable ({type(e).__name__}); set TEST_POSTGRES_URL or POSTGRES_*")
    try:
        _consumers("poses.detect")
    except (AMQPError, OSError) as e:
        pytest.skip(f"RabbitMQ unreachable ({type(e).__name__})")
    endpoint = os.getenv("RUSTFS_ENDPOINT", "http://localhost:9000")
    try:
        urllib.request.urlopen(f"{endpoint}/health", timeout=3).close()
    except OSError as e:
        pytest.skip(f"RustFS unreachable at {endpoint} ({type(e).__name__})")
    if _consumers("poses.detect") or _consumers("poses.advice"):
        pytest.skip("another worker is already consuming poses.detect / poses.advice: stop it first")
    return url


@pytest.fixture(scope="module")
def worker(url: str, storage: RustFS) -> Iterator[None]:
    """The real worker (`worker.cli.consume`) in a thread, with the fake LLM.

    ``storage`` first: the worker does not create the bucket, so it must exist at startup.
    """
    from worker import runtime
    from worker.cli import consume

    getters = [getattr(runtime, n) for n in dir(runtime) if n.startswith("get_")]
    for g in getters:
        g.cache_clear()
    patch = pytest.MonkeyPatch()
    patch.setenv("POSTGRES_DB_URL", url)
    patch.setattr("services.llm.LLM", FakeLLM)
    FakeLLM.mode = "ok"
    failure: list[BaseException] = []

    def run() -> None:
        try:
            consume()
        except BaseException as e:  # noqa: BLE001
            failure.append(e)

    thread = threading.Thread(target=run, name="worker", daemon=True)
    thread.start()
    deadline = time.monotonic() + 60
    while time.monotonic() < deadline and not failure:
        if _consumers("poses.detect") and _consumers("poses.advice"):
            break
        time.sleep(0.5)
    else:
        pytest.fail(f"worker did not start consuming: {failure[0] if failure else 'timeout'}")
    yield
    broker = runtime.get_broker()
    broker.connection.add_callback_threadsafe(broker.channel.stop_consuming)
    thread.join(timeout=30)
    patch.undo()
    for g in getters:
        g.cache_clear()


@pytest.fixture(scope="module")
def db(url: str) -> Iterator[PostgreSQL]:
    database = PostgreSQL().setup_config()
    database.config.url = url
    database.connect()
    yield database
    database.connection.close()


@pytest.fixture(scope="module")
def storage() -> RustFS:
    store = RustFS().setup_config()
    try:
        store.connect()
    except PermanentError:
        store.client.create_bucket(Bucket=store.config.bucket)  # the Go server normally does it
    return store


@pytest.fixture(scope="module")
def seeded(db: PostgreSQL, storage: RustFS) -> Iterator[Callable[[], producer.Seeded]]:
    """``seeded()`` creates a job with its video; everything is removed at the end of the module."""
    created: list[producer.Seeded] = []

    def seed() -> producer.Seeded:
        job = producer.seed(str(VIDEO), db, storage)
        created.append(job)
        return job

    yield seed
    for job in created:
        db.connection.execute("DELETE FROM users WHERE id = %s", (job.user_id,))  # cascades to video and analysis
        storage.client.delete_object(Bucket=storage.config.bucket, Key=job.object_key)


class Observer:
    """Records the ``pose.*.status`` messages and reads the dead-letter queues."""

    def __init__(self):
        self.connection = pika.BlockingConnection(_amqp_params())
        self.channel = self.connection.channel()
        self.channel.exchange_declare(exchange="events", exchange_type="topic", durable=True)
        self.queue = self.channel.queue_declare(queue="", exclusive=True).method.queue
        for key in STATUS_KEYS:
            self.channel.queue_bind(queue=self.queue, exchange="events", routing_key=key)
        self.statuses: list[tuple[str, str, str | None, str | None]] = []  # (routing key, job_id, status, message)

    def drain(self) -> None:
        while True:
            method, _, body = self.channel.basic_get(self.queue, auto_ack=True)
            if method is None:
                return
            data = json.loads(body)
            self.statuses.append((method.routing_key, data["job_id"], data.get("status"), data.get("message")))

    def seen(self, job_id: str, key: RoutingKey) -> list[str]:
        self.drain()
        return [s for k, j, s, _ in self.statuses if j == job_id and k == key]

    def wait_status(self, job_id: str, key: RoutingKey, status: str, timeout: float = 30) -> bool:
        return wait_until(lambda: status in self.seen(job_id, key), timeout)

    def take_dead_letter(self, queue: str, job_id: str, timeout: float = 30) -> dict | None:
        """Remove and return the dead-lettered message of ``job_id`` (others are left in the queue)."""
        found: dict = {}

        def look() -> bool:
            channel = self.connection.channel()
            for _ in range(1000):
                method, _, body = channel.basic_get(queue)
                if method is None:
                    break
                if json.loads(body).get("job_id") == job_id:
                    channel.basic_ack(method.delivery_tag)
                    found.update(json.loads(body))
                    break
            channel.close()  # unacked messages of other jobs go back to the queue
            return bool(found)

        return found if wait_until(look, timeout) else None

    def publish_raw(self, routing_key: RoutingKey, body: bytes) -> None:
        self.channel.basic_publish(exchange="events", routing_key=routing_key, body=body)

    def close(self) -> None:
        self.connection.close()


@pytest.fixture(scope="module")
def observer(worker: None) -> Iterator[Observer]:
    obs = Observer()
    yield obs
    obs.close()


def wait_until(condition: Callable[[], object], timeout: float = TIMEOUT_S, every: float = 0.5):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        value = condition()
        if value:
            return value
        time.sleep(every)
    return None
