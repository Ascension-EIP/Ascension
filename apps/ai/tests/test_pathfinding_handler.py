# @date 2026-11-25
# @file test_pathfinding_handler.py
# @brief Handler of pathfinding.compute.requested with db and broker simulated; the call order is checked.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
import json

import pytest

from common.utils import broker as consume_mod
from common.utils import errors
from common.utils.errors import PermanentError, TransientError
from services.postgresql import PathfindingInput
from shared.models import ClimberMorphology, PathfindingResult, Status
from tests.test_pathfinding_chain import WALL, ladder, square
from worker.handlers import failure
from worker.handlers import pathfinding_compute_request as handler_mod

MORPHOLOGY = ClimberMorphology(height_cm=175, arm_span_cm=178)


def rows(holds) -> list[dict]:
    return [
        {
            "id": h.id,
            "type": h.type.value,
            "contour": {"points": [{"x": float(x), "y": float(y)} for x, y in h.polygon], "bbox": {"x": 0, "y": 0, "w": 1, "h": 1}},
            "usable": h.usable,
            "start_limbs": h.start_limbs,
            "finish_limbs": h.finish_limbs,
        }
        for h in holds
    ]


def pathfinding_input(**changes) -> PathfindingInput:
    base = PathfindingInput(MORPHOLOGY, 400, 800, False, WALL, rows(ladder()), [])
    return base._replace(**changes)


class Job:
    """Fake broker and database sharing one call recorder."""

    def __init__(self, data: PathfindingInput | None = None, status=Status.PENDING):
        self.calls: list[tuple] = []
        self.status, self.data = status, data or pathfinding_input()
        self.status_error: Exception | None = None
        self.input_errors: list[Exception] = []
        self.complete_errors: list[Exception] = []
        self.path: PathfindingResult | None = None

    def submit(self, fn, *args):
        fn(*args)

    def ack(self, tag):
        self.calls.append(("ack",))

    def nack(self, tag):
        self.calls.append(("nack",))

    def publish(self, key, payload):
        self.calls.append(("publish", str(key), payload.status.value, payload.message))

    def get_ghost_status(self, ghost_id):
        if self.status_error:
            raise self.status_error
        return self.status

    def mark_ghost_started(self, ghost_id):
        self.calls.append(("db.started",))
        self.status = Status.STARTED

    def update_ghost_progress(self, ghost_id, progress):
        self.calls.append(("db.progress", progress))
        self.status = Status.RUNNING

    def get_ghost_input(self, ghost_id):
        if self.input_errors:
            raise self.input_errors.pop(0)
        self.calls.append(("db.input", ghost_id))
        return self.data

    def complete_ghost(self, ghost_id, path):
        if self.complete_errors:
            raise self.complete_errors.pop(0)
        self.calls.append(("db.complete",))
        self.path, self.status = path, Status.SUCCESS

    def fail_ghost(self, ghost_id, message):
        self.calls.append(("db.fail", message))
        self.status = Status.FAILED

    def names(self):
        return [c[0] if c[0] != "publish" else f"{c[1]}={c[2]}" for c in self.calls]


class Method:
    delivery_tag = 1


def run(monkeypatch, job: Job, body: bytes = b'{"job_id": "g"}') -> None:
    monkeypatch.setattr(errors.time, "sleep", lambda _s: None)
    monkeypatch.setattr(consume_mod, "get_broker", lambda: job)
    for mod in (handler_mod, failure):
        monkeypatch.setattr(mod, "get_broker", lambda: job)
        monkeypatch.setattr(mod, "get_db", lambda: job)
    handler_mod.pathfinding_compute_request(None, Method(), None, body)


def failed_message(job: Job) -> str:
    (message,) = [c[1] for c in job.calls if c[0] == "db.fail"]
    assert ("publish", "pathfinding.compute.status", "failed", message) in job.calls  # same short message in the status
    assert job.names()[-3:] == ["db.fail", "pathfinding.compute.status=failed", "nack"]
    return message


def test_success_reads_the_input_computes_and_stores_the_path(monkeypatch):
    job = Job()
    run(monkeypatch, job)
    assert job.names() == [
        "db.started",
        "pathfinding.compute.status=started",
        "db.progress",
        "pathfinding.compute.status=running",
        "db.input",
        "db.progress",
        "db.complete",
        "pathfinding.compute.status=success",
        "ack",
    ]
    assert job.status == Status.SUCCESS
    PathfindingResult.model_validate(json.loads(job.path.model_dump_json()))
    assert len(job.path.steps) >= 4 and (job.path.image_width, job.path.image_height) == (400, 800)
    assert job.path.wall_angle_deg == WALL.angle_deg


def test_the_preference_of_the_request_is_used(monkeypatch):
    easy, power = Job(), Job()
    run(monkeypatch, easy)
    run(monkeypatch, power, b'{"job_id": "g", "preference": "power"}')
    assert len(power.path.steps) <= len(easy.path.steps)


def test_the_selection_and_feet_free_of_the_route_are_used(monkeypatch):
    job = Job(pathfinding_input(selected_ids=["0", "1", "2", "3", "4"], feet_free=True))
    run(monkeypatch, job)
    used = {v for s in job.path.steps for v in s.holds.model_dump().values() if v}
    hands = {v for s in job.path.steps for k, v in s.holds.model_dump().items() if v and k.endswith("hand")}
    assert hands <= {"0", "1", "2", "3", "4"} and used


def test_redelivery_of_a_computed_ghost_does_nothing(monkeypatch):
    job = Job(status=Status.SUCCESS)
    run(monkeypatch, job)
    assert job.names() == ["ack"]


def test_unknown_ghost_fails_with_a_short_message(monkeypatch):
    job = Job()
    job.status_error = PermanentError("job g: no such row")
    run(monkeypatch, job)
    assert failed_message(job) == "Job not found"


def test_route_without_wall_fails_permanently(monkeypatch):
    job = Job(pathfinding_input(wall=None))
    run(monkeypatch, job)
    assert failed_message(job) == "Wall geometry missing"


def test_a_homography_that_is_not_3x3_fails_permanently(monkeypatch):
    job = Job(pathfinding_input(wall=WALL.model_copy(update={"homography": [[1, 0, 0], [0, 1, 0]]})))
    run(monkeypatch, job)
    assert failed_message(job) == "Wall geometry invalid"


def test_no_beta_names_the_holds_around_the_missing_passage(monkeypatch):
    from worker._4_pathfinding._4_pathfinding import PhotoHold

    holds = [PhotoHold("low", square(100, 20)), PhotoHold("high", square(100, 380))]
    job = Job(pathfinding_input(holds=rows(holds)))
    run(monkeypatch, job)
    message = failed_message(job)
    assert message.startswith("No beta") and "low" in message and "high" in message and len(message) < 120


def test_no_usable_hold_fails_with_a_short_message(monkeypatch):
    holds = ladder(3)
    job = Job(pathfinding_input(holds=[{**r, "usable": False} for r in rows(holds)]))
    run(monkeypatch, job)
    assert failed_message(job) == "Pathfinding failed"


def test_stored_data_that_cannot_be_read_fails_permanently(monkeypatch):
    job = Job()
    job.input_errors = [PermanentError("ghost g: stored morphology or wall plane is invalid")]
    run(monkeypatch, job)
    assert failed_message(job) == "Invalid pathfinding data"


def test_an_invalid_hold_contour_fails_permanently(monkeypatch):
    job = Job(pathfinding_input(holds=[{"id": "a", "type": "unknown", "contour": {"points": "nope"}, "usable": True}]))
    run(monkeypatch, job)
    assert failed_message(job) == "Invalid pathfinding data"


def test_database_down_is_retried_then_failed_once(monkeypatch):
    job = Job()
    job.input_errors = [TransientError("database unavailable")] * 3
    run(monkeypatch, job)
    assert job.names().count("db.fail") == 1
    assert failed_message(job) == "Database unavailable"


def test_transient_database_error_while_completing_is_retried(monkeypatch):
    job = Job()
    job.complete_errors = [TransientError("database unavailable")]
    run(monkeypatch, job)
    assert job.names()[-3:] == ["db.complete", "pathfinding.compute.status=success", "ack"]


def test_unexpected_error_has_no_detail_in_the_status(monkeypatch):
    job = Job(pathfinding_input(holds=None))  # the chain meets a TypeError
    run(monkeypatch, job)
    assert failed_message(job) == "Analysis failed"


@pytest.mark.parametrize("body", [b'{"job_id": "g", "preference": "fast"}', b'{"preference": "easy"}'])
def test_an_invalid_request_goes_to_the_dead_letter_queue(monkeypatch, body):
    job = Job()
    run(monkeypatch, job, body)
    assert job.names() == ["nack"]

