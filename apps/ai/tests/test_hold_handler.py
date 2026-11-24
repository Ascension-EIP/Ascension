# @date 2026-11-24
# @file test_hold_handler.py
# @brief Handler of holds.detect.requested with db, storage, broker and model simulated; the call order is checked.
# @project Ascension
# @author Livoooo <zarigu92@gmail.com>
# @copyright (c) 2026 Ascension
# @status done
import sys
from contextlib import contextmanager
from types import SimpleNamespace

from common.utils import broker as consume_mod
from common.utils import errors
from common.utils.errors import PermanentError, TransientError
from shared.models import HoldDetectResult, Status
from worker.handlers import failure
from worker.handlers import hold_detect_request as holds_mod

RESULT = HoldDetectResult.model_validate(
    {
        "image_width": 400,
        "image_height": 300,
        "holds": [
            {
                "type": "unknown",
                "confidence": 0.9,
                "contour": {"points": [{"x": 1, "y": 2}, {"x": 5, "y": 2}, {"x": 5, "y": 6}], "bbox": {"x": 1, "y": 2, "w": 4, "h": 4}},
                "color": {"name": "blue", "rgb": [20, 60, 200], "distance": 3.2},
            }
        ],
    }
)
BODY = b'{"job_id": "r", "object_key": "routes/r.jpg"}'


class Route:
    """Fake broker, database, storage and hold detector sharing one call recorder."""

    def __init__(self, status=Status.PENDING):
        self.calls: list[tuple] = []
        self.status = status
        self.download_error: Exception | None = None
        self.detect_error: Exception | None = None
        self.model_missing = False
        self.save_errors: list[Exception] = []
        self.saved: HoldDetectResult | None = None

    # broker
    def submit(self, fn, *args):
        fn(*args)

    def ack(self, tag):
        self.calls.append(("ack",))

    def nack(self, tag):
        self.calls.append(("nack",))

    def publish(self, key, payload):
        self.calls.append(("publish", str(key), payload.status.value, payload.message))

    # db
    def get_route_status(self, route_id):
        return self.status

    def mark_route_started(self, route_id):
        self.calls.append(("db.started",))
        self.status = Status.STARTED

    def update_route_progress(self, route_id, progress):
        self.calls.append(("db.progress", progress))
        self.status = Status.RUNNING

    def save_holds(self, route_id, result):
        if self.save_errors:
            raise self.save_errors.pop(0)
        self.calls.append(("db.save_holds",))
        self.saved = result

    def complete_route(self, route_id):
        self.calls.append(("db.complete",))
        self.status = Status.SUCCESS

    def fail_route(self, route_id, message):
        self.calls.append(("db.fail", message))
        self.status = Status.FAILED

    # storage
    @contextmanager
    def download_temp(self, key):
        if self.download_error:
            raise self.download_error
        self.calls.append(("download", key))
        yield "/tmp/wall.jpg"

    def names(self):
        return [c[0] if c[0] != "publish" else f"{c[1]}={c[2]}" for c in self.calls]


class Method:
    delivery_tag = 1


def run(monkeypatch, w: Route) -> None:
    monkeypatch.setattr(errors.time, "sleep", lambda _s: None)
    monkeypatch.setattr(consume_mod, "get_broker", lambda: w)
    for mod in (holds_mod, failure):
        monkeypatch.setattr(mod, "get_broker", lambda: w)
        monkeypatch.setattr(mod, "get_db", lambda: w)
    monkeypatch.setattr(holds_mod, "get_storage", lambda: w)

    def get_hold_segmenter():
        if w.model_missing:
            raise FileNotFoundError("hold model not found: resources/holds_seg.onnx")
        return "segmenter"

    def detect_holds(path, segmenter):
        w.calls.append(("detect", path, segmenter))
        if w.detect_error:
            raise w.detect_error
        return RESULT

    monkeypatch.setattr(holds_mod, "get_hold_segmenter", get_hold_segmenter)
    monkeypatch.setitem(sys.modules, "worker._3_holds._0_hold_detect", SimpleNamespace(detect_holds=detect_holds))
    holds_mod.hold_detect_request(None, Method(), None, BODY)


def test_success_stores_the_holds_then_completes_the_route(monkeypatch):
    w = Route()
    run(monkeypatch, w)
    assert w.names() == [
        "db.started",
        "holds.detect.status=started",
        "db.progress",
        "holds.detect.status=running",
        "download",
        "detect",
        "db.save_holds",
        "db.complete",
        "holds.detect.status=success",
        "ack",
    ]
    assert ("download", "routes/r.jpg") in w.calls
    assert ("detect", "/tmp/wall.jpg", "segmenter") in w.calls
    assert w.saved is RESULT
    assert w.status == Status.SUCCESS


def test_redelivery_of_a_detected_route_does_nothing(monkeypatch):
    w = Route(status=Status.SUCCESS)
    run(monkeypatch, w)
    assert w.names() == ["ack"]


def test_missing_photo_fails_the_route_once_and_is_dead_lettered(monkeypatch):
    w = Route()
    w.download_error = PermanentError("storage object or bucket not found (NoSuchKey)")
    run(monkeypatch, w)
    assert w.names()[-3:] == ["db.fail", "holds.detect.status=failed", "nack"]
    assert ("db.fail", "Photo not found") in w.calls
    assert ("publish", "holds.detect.status", "failed", "Photo not found") in w.calls


def test_unreadable_photo_fails_with_a_short_message(monkeypatch):
    w = Route()
    w.detect_error = PermanentError("unreadable image: wall.jpg")
    run(monkeypatch, w)
    assert ("db.fail", "Unreadable photo") in w.calls
    assert w.names()[-1] == "nack"


def test_missing_model_fails_before_taking_the_job(monkeypatch):
    w = Route()
    w.model_missing = True
    run(monkeypatch, w)
    assert w.names() == ["db.fail", "holds.detect.status=failed", "nack"]
    assert ("db.fail", "Hold model unavailable") in w.calls


def test_transient_storage_error_is_retried_then_failed_once(monkeypatch):
    w = Route()
    w.download_error = TransientError("storage unreachable (EndpointConnectionError)")
    run(monkeypatch, w)
    assert w.names().count("db.fail") == 1
    assert ("db.fail", "Storage unavailable") in w.calls


def test_transient_database_error_while_saving_is_retried(monkeypatch):
    w = Route()
    w.save_errors = [TransientError("database unavailable")]
    run(monkeypatch, w)
    assert w.names()[-3:] == ["db.complete", "holds.detect.status=success", "ack"]
    assert w.saved is RESULT


def test_unexpected_detection_error_has_no_detail_in_the_status(monkeypatch):
    w = Route()
    w.detect_error = RuntimeError("onnxruntime: secret internal detail")
    run(monkeypatch, w)
    failed = [c for c in w.calls if c[0] == "publish" and c[2] == "failed"]
    assert failed == [("publish", "holds.detect.status", "failed", "Analysis failed")]
