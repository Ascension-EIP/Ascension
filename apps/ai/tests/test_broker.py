# @date 2026-11-01
# @file test_broker.py
# @brief File description.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
import pytest
from pydantic import BaseModel

from common.utils import broker as consume_mod
from common.utils import errors
from common.utils.errors import PermanentError, TransientError, with_retry
from services.rabbitmq import Broker


class Msg(BaseModel):
    job_id: str


class FakeBroker:
    """Runs jobs inline and records the message decision."""

    def __init__(self):
        self.calls: list[tuple[str, int]] = []

    def submit(self, fn, *args):
        fn(*args)

    def ack(self, tag):
        self.calls.append(("ack", tag))

    def nack(self, tag):
        self.calls.append(("nack", tag))


class Method:
    delivery_tag = 7


@pytest.fixture
def fake(monkeypatch):
    f = FakeBroker()
    monkeypatch.setattr(consume_mod, "get_broker", lambda: f)
    monkeypatch.setattr(errors.time, "sleep", lambda _s: None)
    return f


def deliver(handler, body: bytes):
    consume_mod.consume(Msg)(handler)(None, Method(), None, body)


def test_with_retry_retries_transient_only(monkeypatch):
    delays = []
    monkeypatch.setattr(errors.time, "sleep", delays.append)
    n = {"c": 0}

    def flaky():
        n["c"] += 1
        if n["c"] < 3:
            raise TransientError("down")
        return "ok"

    assert with_retry(flaky, base_delay=1) == "ok"
    assert n["c"] == 3
    assert delays == [1, 2]


def test_with_retry_gives_up_after_attempts():
    n = {"c": 0}

    def down():
        n["c"] += 1
        raise TransientError("down")

    with pytest.raises(TransientError):
        with_retry(down, base_delay=0)
    assert n["c"] == 3


def test_with_retry_does_not_retry_other_errors():
    n = {"c": 0}

    def bad():
        n["c"] += 1
        raise PermanentError("bad")

    with pytest.raises(PermanentError):
        with_retry(bad, base_delay=0)
    assert n["c"] == 1


def test_valid_payload_is_acked(fake):
    seen = []
    deliver(seen.append, b'{"job_id": "a"}')
    assert seen == [Msg(job_id="a")]
    assert fake.calls == [("ack", 7)]


@pytest.mark.parametrize("body", [b"not json", b'{"other": 1}', b"\xff"])
def test_invalid_payload_is_nacked_without_running_handler(fake, body):
    deliver(lambda p: pytest.fail("handler must not run"), body)
    assert fake.calls == [("nack", 7)]


def test_transient_error_is_tried_3_times_then_nacked(fake):
    n = {"c": 0}

    def handler(_p):
        n["c"] += 1
        raise TransientError("down")

    deliver(handler, b'{"job_id": "a"}')
    assert n["c"] == 3
    assert fake.calls == [("nack", 7)]


@pytest.mark.parametrize("exc", [PermanentError("bad"), RuntimeError("boom")])
def test_permanent_or_unknown_error_is_tried_once_then_nacked(fake, exc):
    n = {"c": 0}

    def handler(_p):
        n["c"] += 1
        raise exc

    deliver(handler, b'{"job_id": "a"}')
    assert n["c"] == 1
    assert fake.calls == [("nack", 7)]


def test_conflicting_callbacks_on_one_queue_raise(monkeypatch):
    from common.models.broker import Bind
    from services import rabbitmq

    monkeypatch.setattr(
        rabbitmq,
        "BROKER_BINDINGS",
        [Bind("q", "a", lambda *_: None), Bind("q", "b", lambda *_: None)],
    )
    with pytest.raises(ValueError, match="different callbacks"):
        Broker().start_consuming()
