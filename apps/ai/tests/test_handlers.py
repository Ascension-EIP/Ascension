# @date 2026-11-02
# @file test_handlers.py
# @brief Handler tests with db, storage, broker and LLM simulated; the call order is checked.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
import sys
from contextlib import contextmanager
from types import SimpleNamespace

import pytest

from common.utils import broker as consume_mod
from common.utils import errors
from common.utils.errors import PermanentError, TransientError
from shared.models import AnalysisResult, Status
from tests.test_pose_advice import make_result
from worker.handlers import failure
from worker.handlers import pose_advice_request as advice_mod
from worker.handlers import pose_detect_request as detect_mod

RESULT = AnalysisResult.model_validate(make_result(n=20))
GOOD_ANSWER = {
    "summary": "ok",
    "items": [{"category": "technique", "title": "t", "description": "d", "priority": 2}],
}
SECRET = "sk-secret-key"


class World:
    """One recorder shared by the fake broker, database, storage and LLM."""

    def __init__(self, status=Status.PENDING, result=None, llm_error=None, llm_configured=True):
        self.calls: list[tuple] = []
        self.status, self.result, self.hints = status, result, "previous" if status == Status.SUCCESS else None
        self.llm_error, self.llm_configured = llm_error, llm_configured
        self.download_error: Exception | None = None
        self.progress: list[int] = []
        self.progress_error: Exception | None = None  # raised by the writes made during the MediaPipe run

    # broker
    def submit(self, fn, *args):
        fn(*args)

    def ack(self, tag):
        self.calls.append(("ack",))

    def nack(self, tag):
        self.calls.append(("nack",))

    def publish(self, key, payload):
        self.calls.append(("publish", str(key), getattr(getattr(payload, "status", None), "value", ""), getattr(payload, "message", None)))

    # db
    def get_status(self, job_id):
        return self.status

    def mark_started(self, job_id):
        self.calls.append(("db.started",))
        self.status = Status.STARTED

    def update_progress(self, job_id, p):
        if self.progress_error and 5 < p < 80:
            raise self.progress_error
        self.calls.append(("db.progress", p))
        self.progress.append(p)
        self.status = Status.RUNNING

    def save_result(self, job_id, result):
        self.calls.append(("db.save_result",))
        self.result = result

    def get_result(self, job_id):
        if self.result is None:
            raise PermanentError("no result")
        return self.result

    def save_hints(self, job_id, hints):
        self.calls.append(("db.save_hints",))
        self.hints = hints

    def complete(self, job_id):
        self.calls.append(("db.complete",))
        self.status = Status.SUCCESS

    def fail(self, job_id, message):
        self.calls.append(("db.fail", message))
        self.status = Status.FAILED

    # storage
    @contextmanager
    def download_temp(self, key):
        if self.download_error:
            raise self.download_error
        self.calls.append(("download", key))
        yield "/tmp/video.mp4"

    # llm
    config = SimpleNamespace(model="m")

    def generate_json(self, prompt):
        self.calls.append(("llm",))
        if self.llm_error:
            raise self.llm_error
        return GOOD_ANSWER

    def names(self):
        return [c[0] if c[0] != "publish" else f"{c[1]}={c[2]}" for c in self.calls]


class Method:
    delivery_tag = 1


def install(monkeypatch, w: World):
    monkeypatch.setattr(errors.time, "sleep", lambda _s: None)
    monkeypatch.setattr(consume_mod, "get_broker", lambda: w)
    for mod in (detect_mod, advice_mod, failure):
        monkeypatch.setattr(mod, "get_broker", lambda: w)
        monkeypatch.setattr(mod, "get_db", lambda: w)
    monkeypatch.setattr(detect_mod, "get_storage", lambda: w)

    def get_llm():
        if not w.llm_configured:
            raise ValueError("LLM_BASE_URL must be set")
        return w

    monkeypatch.setattr(advice_mod, "get_llm", get_llm)

    def detect_pose(path, render_path=None, on_progress=None):
        w.calls.append(("detect",))
        for pct in range(101):
            on_progress(pct)
        return RESULT

    monkeypatch.setitem(sys.modules, "worker._1_mediapipe._0_pose_detect", SimpleNamespace(detect_pose=detect_pose))


def detect(w):
    detect_mod.pose_detect_request(None, Method(), None, b'{"job_id": "j", "object_key": "videos/a.mp4"}')


def advice(w):
    advice_mod.pose_advice_request(None, Method(), None, b'{"job_id": "j"}')


def statuses(w):
    return [c for c in w.calls if c[0] == "publish"]


def test_detect_success_ends_at_85_running_then_completed(monkeypatch):
    w = World()
    install(monkeypatch, w)
    detect(w)
    names = w.names()
    assert names[:5] == [
        "db.started",
        "pose.detect.status=started",
        "db.progress",
        "pose.detect.status=running",
        "download",
    ]
    assert names[-5:] == [
        "db.progress",
        "db.save_result",
        "pose.detect.status=success",
        "pose.detect.completed=",
        "ack",
    ]
    assert w.progress == [5, *range(10, 71, 5), 80]  # one write per 5%, then 80 (steps done)
    assert w.status == Status.RUNNING and w.result == RESULT  # stored (85), analysis not over
    assert "db.complete" not in names and "db.fail" not in names


def test_failed_progress_write_does_not_fail_the_job(monkeypatch):
    w = World()
    w.progress_error = TransientError("database unavailable")
    install(monkeypatch, w)
    monkeypatch.setattr("time.sleep", lambda s: pytest.fail("a progress write must not be retried"))
    detect(w)
    names = w.names()
    assert w.progress == [5, 80] and w.result == RESULT  # computation kept, result stored
    assert "db.fail" not in names and "nack" not in names and names[-1] == "ack"
    assert "pose.detect.completed=" in names


def test_detect_publishes_completed_job_after_success(monkeypatch):
    w = World()
    install(monkeypatch, w)
    detect(w)
    keys = [c[1] for c in statuses(w)]
    assert keys[-2:] == ["pose.detect.status", "pose.detect.completed"]


def test_missing_video_fails_once_and_is_dead_lettered(monkeypatch):
    w = World()
    w.download_error = PermanentError("storage object or bucket not found (NoSuchKey)")
    install(monkeypatch, w)
    detect(w)
    assert w.names() == [
        "db.started",
        "pose.detect.status=started",
        "db.progress",
        "pose.detect.status=running",
        "db.fail",
        "pose.detect.status=failed",
        "nack",
    ]
    assert ("db.fail", "Video not found") in w.calls
    assert ("publish", "pose.detect.status", "failed", "Video not found") in w.calls
    assert w.status == Status.FAILED


def test_transient_storage_error_is_retried_inside_then_failed_once(monkeypatch):
    w = World()
    attempts = []
    w.download_error = TransientError("down")
    real = w.download_temp

    def counting(key):
        attempts.append(key)
        return real(key)

    w.download_temp = counting
    install(monkeypatch, w)
    detect(w)
    assert len(attempts) == 3  # with_retry around the download only, not 3 x 3
    assert w.names().count("pose.detect.status=started") == 1
    assert w.names().count("pose.detect.status=failed") == 1
    assert ("db.fail", "Storage unavailable") in w.calls
    assert w.names()[-1] == "nack"


def test_unexpected_pose_error_has_no_traceback_in_status(monkeypatch):
    w = World()
    install(monkeypatch, w)

    def boom(*a, **k):
        raise RuntimeError("secret detail")

    sys.modules["worker._1_mediapipe._0_pose_detect"].detect_pose = boom
    detect(w)
    msg = next(c for c in w.calls if c[0] == "publish" and c[2] == "failed")[3]
    assert msg == "Analysis failed" and "Traceback" not in msg and "secret" not in msg
    assert w.names()[-1] == "nack"


def test_detect_redelivery_of_a_finished_job_does_nothing(monkeypatch):
    w = World(status=Status.SUCCESS)
    install(monkeypatch, w)
    detect(w)
    assert w.names() == ["ack"]


def test_advice_success_writes_hints_then_completes(monkeypatch):
    w = World(status=Status.RUNNING, result=RESULT)
    install(monkeypatch, w)
    advice(w)
    assert w.names() == [
        "pose.advice.status=started",
        "db.progress",
        "pose.advice.status=running",
        "llm",
        "db.save_hints",
        "db.complete",
        "pose.advice.status=success",
        "ack",
    ]
    assert w.progress == [90] and w.status == Status.SUCCESS and w.hints.model == "m"


@pytest.mark.parametrize(
    "kwargs,message",
    [
        ({"llm_error": TransientError(f"HTTP 503 https://x/?key={SECRET}")}, "LLM unavailable"),
        ({"llm_error": PermanentError(f"rejected {SECRET}")}, "LLM could not produce advice"),
        ({"llm_configured": False}, "LLM not configured"),
    ],
)
def test_llm_failure_ends_in_success_without_hints(monkeypatch, kwargs, message):
    w = World(status=Status.RUNNING, result=RESULT, **kwargs)
    install(monkeypatch, w)
    advice(w)
    names = w.names()
    assert names[-3:] == ["db.complete", "pose.advice.status=failed", "ack"]
    assert "db.save_hints" not in names and "db.fail" not in names
    assert w.status == Status.SUCCESS and w.hints is None
    assert ("publish", "pose.advice.status", "failed", message) in w.calls
    assert SECRET not in repr(w.calls)


def test_failed_relaunch_keeps_previous_hints_and_success(monkeypatch):
    w = World(status=Status.SUCCESS, result=RESULT, llm_error=TransientError("down"))
    install(monkeypatch, w)
    advice(w)
    assert w.hints == "previous" and w.status == Status.SUCCESS
    assert w.names() == ["pose.advice.status=started", "llm", "llm", "llm", "pose.advice.status=failed", "ack"]  # 3 LLM tries


def test_successful_relaunch_does_not_reset_the_analysis(monkeypatch):
    w = World(status=Status.SUCCESS, result=RESULT)
    install(monkeypatch, w)
    advice(w)
    names = w.names()
    assert "db.progress" not in names and "db.complete" not in names
    assert "pose.advice.status=running" not in names
    assert names[-3:] == ["db.save_hints", "pose.advice.status=success", "ack"]
    assert w.status == Status.SUCCESS and w.hints != "previous"


def test_advice_without_result_fails_once_and_is_dead_lettered(monkeypatch):
    w = World(status=Status.RUNNING, result=None)
    install(monkeypatch, w)
    advice(w)
    assert w.names() == ["pose.advice.status=started", "db.fail", "pose.advice.status=failed", "nack"]
    assert ("db.fail", "Result not found") in w.calls


def test_no_status_message_contains_a_traceback(monkeypatch):
    w = World()
    w.download_error = PermanentError("x")
    install(monkeypatch, w)
    detect(w)
    for c in statuses(w):
        assert "Traceback" not in (c[3] or "") and "\n" not in (c[3] or "")
