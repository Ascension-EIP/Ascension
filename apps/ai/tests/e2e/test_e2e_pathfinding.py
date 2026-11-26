# @date 2026-11-25
# @file test_e2e_pathfinding.py
# @brief End-to-end pathfinding flow on the real RabbitMQ, PostgreSQL and RustFS: hold detection with wall, then pathfinding.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""Photo of a route -> ``holds.detect.requested`` -> route ``success`` with ``wall_plane`` -> `pathfindings` row seeded
-> ``pathfinding.compute.requested`` -> pathfinding ``success`` with a valid ``result``.

Real: RabbitMQ, PostgreSQL, RustFS, the worker (consumer, handlers, SQL), the plane fit, the A* search and
the posture. Fake: the depth model (a wall facing the camera at 3 m) and the hold model (the squares of a
ladder drawn on the photo), both replaced by patching the getters of the handlers like the fake LLM; a
synthetic photo is no scene for the real models. ``test_real_models_*`` uses the real ones on a real photo.
"""

from collections.abc import Callable, Iterator
from pathlib import Path

import cv2
import numpy as np
import pytest

import producer
from services.postgresql import PostgreSQL
from services.rustfs import RustFS
from shared.models import (
    ClimberMorphology,
    HoldDetectRequest,
    PathfindingComputeRequest,
    PathfindingResult,
    RoutingKey,
    WallPlane,
)
from tests.e2e.conftest import APP, Observer, wait_until
from worker._3_holds._1_hold_segment import Segment
from worker.handlers import hold_detect_request as holds_mod

pytestmark = [pytest.mark.e2e, pytest.mark.usefixtures("worker")]

WIDTH, HEIGHT = 400, 800
LADDER = [  # 12 holds 25 px (19 cm at 3 m with f = 400 px) apart, the lowest at the bottom
    [[190 + 20 * (i % 2) + dx, 760 - 25 * i + dy] for dx, dy in ((-7, -7), (7, -7), (7, 7), (-7, 7))] for i in range(12)
]
GAP = [LADDER[0], [[p[0], p[1] - 700] for p in LADDER[1]]]  # two holds 525 cm apart: no beta
REAL_PHOTO = APP.parents[1] / "docs" / "Ascension" / "resources" / "images" / "deck" / "climb_olivier.jpeg"
PHOTO_ROWS = "SELECT status, progress, error, wall_plane, wall_angle_deg, image_width, image_height FROM routes WHERE id = %s"
PATHFINDING_ROWS = "SELECT status, progress, error, result, completed_at, processing_time_ms FROM pathfindings WHERE id = %s"


class FakeDepth:
    def __call__(self, image, focal_px=None):
        return np.full(image.shape[:2], 3.0, np.float32), 400.0


class FakeSegmenter:
    polygons = LADDER  # tests switch it before a detection

    def __call__(self, image, confidence=0.1):
        return [Segment("hold", 0.9, np.array([0, 0, 1, 1.0]), np.array(p, float)) for p in self.polygons]


@pytest.fixture(scope="module", autouse=True)
def fake_models(worker) -> Iterator[None]:
    patch = pytest.MonkeyPatch()
    patch.setattr(holds_mod, "get_depth_estimator", lambda: FakeDepth())
    patch.setattr(holds_mod, "get_hold_segmenter", lambda: FakeSegmenter())
    yield
    patch.undo()


@pytest.fixture(scope="module")
def pathfinding_observer(observer: Observer) -> Observer:
    for key in (RoutingKey.HOLDS_DETECT_STATUS, RoutingKey.PATHFINDING_COMPUTE_STATUS):
        observer.channel.queue_bind(queue=observer.queue, exchange="events", routing_key=key)
    return observer


@pytest.fixture(scope="module")
def photo(tmp_path_factory) -> Path:
    """Grey wall with the holds of the ladder drawn in blue."""
    image = np.full((HEIGHT, WIDTH, 3), 150, np.uint8)
    for polygon in LADDER:
        cv2.fillPoly(image, [np.array(polygon, np.int32)], (200, 60, 20))
    path = tmp_path_factory.mktemp("pathfinding") / "wall.png"
    cv2.imwrite(str(path), image)
    return path


@pytest.fixture(scope="module")
def seeded_route(db: PostgreSQL, storage: RustFS, photo: Path) -> Iterator[Callable[[], producer.SeededRoute]]:
    created: list[producer.SeededRoute] = []

    def seed() -> producer.SeededRoute:
        route = producer.seed_route(str(photo), db, storage)
        created.append(route)
        return route

    yield seed
    for route in created:
        db.connection.execute("DELETE FROM users WHERE id = %s", (route.user_id,))  # cascades to routes, holds and pathfindings
        storage.client.delete_object(Bucket=storage.config.bucket, Key=route.object_key)


def route_row(db: PostgreSQL, route_id: str) -> dict:
    keys = ("status", "progress", "error", "wall_plane", "wall_angle_deg", "image_width", "image_height")
    return dict(zip(keys, db.connection.execute(PHOTO_ROWS, (route_id,)).fetchone(), strict=True))


def pathfinding_row(db: PostgreSQL, pathfinding_id: str) -> dict:
    keys = ("status", "progress", "error", "result", "completed_at", "processing_time_ms")
    return dict(zip(keys, db.connection.execute(PATHFINDING_ROWS, (pathfinding_id,)).fetchone(), strict=True))


def wait_ended(read: Callable[[], dict]) -> dict:
    ended = wait_until(lambda: read() if read()["status"] in ("success", "failed") else None, timeout=120)
    assert ended, f"job did not end: {read()}"
    return ended


def detect(db: PostgreSQL, route: producer.SeededRoute, gravity: list[float] | None = None) -> dict:
    producer.publish(
        RoutingKey.HOLDS_DETECT_REQUESTED, HoldDetectRequest(job_id=route.route_id, object_key=route.object_key, gravity=gravity)
    )
    return wait_ended(lambda: route_row(db, route.route_id))


def compute(db: PostgreSQL, route: producer.SeededRoute, **request) -> tuple[str, dict]:
    pathfinding = producer.seed_pathfinding(route.route_id, ClimberMorphology(height_cm=175, arm_span_cm=178), db)
    assert pathfinding_row(db, pathfinding.pathfinding_id)["status"] == "pending"
    producer.publish(RoutingKey.PATHFINDING_COMPUTE_REQUESTED, PathfindingComputeRequest(job_id=pathfinding.pathfinding_id, **request))
    return pathfinding.pathfinding_id, wait_ended(lambda: pathfinding_row(db, pathfinding.pathfinding_id))


def test_route_then_pathfinding(db: PostgreSQL, seeded_route, pathfinding_observer: Observer):
    route = seeded_route()
    FakeSegmenter.polygons = LADDER
    detected = detect(db, route, gravity=[0.0, 9.8, 0.0])
    assert detected["status"] == "success" and detected["error"] is None and detected["progress"] == 100
    assert (detected["image_width"], detected["image_height"]) == (WIDTH, HEIGHT)
    wall = WallPlane.model_validate(detected["wall_plane"])
    assert len(wall.homography) == 3 and wall.inlier_ratio > 0.99 and wall.angle_deg == pytest.approx(0, abs=0.5)
    assert float(detected["wall_angle_deg"]) == pytest.approx(0, abs=0.5)
    assert pathfinding_observer.wait_status(route.route_id, RoutingKey.HOLDS_DETECT_STATUS, "success")

    holds = db.connection.execute("SELECT id, contour FROM holds WHERE route_id = %s", (route.route_id,)).fetchall()
    assert len(holds) == len(LADDER)
    lowest = max(holds, key=lambda h: h[1]["bbox"]["y"])  # the user marks the start hold: both hands start on it
    db.connection.execute("UPDATE holds SET start_limbs = 2 WHERE id = %s", (lowest[0],))

    pathfinding_id, final = compute(db, route, preference="easy")
    assert final["status"] == "success" and final["error"] is None and final["progress"] == 100, final
    assert final["completed_at"] is not None and isinstance(final["processing_time_ms"], int)
    path = PathfindingResult.model_validate(final["result"])
    assert (path.image_width, path.image_height) == (WIDTH, HEIGHT) and path.wall_angle_deg == pytest.approx(0, abs=0.5)
    assert len(path.steps) >= 4 and [s.index for s in path.steps] == list(range(len(path.steps)))
    assert all(len(s.landmarks) == 33 for s in path.steps)
    ids = {str(h[0]) for h in holds}
    assert {v for s in path.steps for v in s.holds.model_dump().values() if v} <= ids
    assert path.steps[0].holds.left_hand == path.steps[0].holds.right_hand == str(lowest[0])  # the mark was honoured
    statuses = pathfinding_observer.seen(pathfinding_id, RoutingKey.PATHFINDING_COMPUTE_STATUS)
    assert {"started", "running", "success"} <= set(statuses)
    assert statuses.index("started") < statuses.index("running") < statuses.index("success")


def test_a_route_without_wall_fails_the_pathfinding_with_a_short_message(db: PostgreSQL, seeded_route, pathfinding_observer: Observer):
    route = seeded_route()  # never detected: no wall
    pathfinding_id, final = compute(db, route)
    assert final["status"] == "failed" and final["result"] is None and final["error"] == "Wall geometry missing"
    assert pathfinding_observer.wait_status(pathfinding_id, RoutingKey.PATHFINDING_COMPUTE_STATUS, "failed")
    assert pathfinding_observer.take_dead_letter("pathfinding.compute.dlq", pathfinding_id)


def test_no_beta_names_the_holds_around_the_gap(db: PostgreSQL, seeded_route, pathfinding_observer: Observer):
    route = seeded_route()
    FakeSegmenter.polygons = GAP
    try:
        assert detect(db, route)["status"] == "success"
    finally:
        FakeSegmenter.polygons = LADDER
    ids = {str(i) for (i,) in db.connection.execute("SELECT id FROM holds WHERE route_id = %s", (route.route_id,)).fetchall()}
    _, final = compute(db, route)
    assert final["status"] == "failed" and final["result"] is None
    assert final["error"].startswith("No beta between holds ") and all(i in final["error"] for i in ids)


def test_a_wall_failure_does_not_fail_the_detection(db: PostgreSQL, seeded_route, monkeypatch):
    class Noise:
        def __call__(self, image, focal_px=None):
            return np.random.default_rng(0).uniform(1, 9, image.shape[:2]).astype(np.float32), 400.0

    monkeypatch.setattr(holds_mod, "get_depth_estimator", lambda: Noise())
    route = seeded_route()
    detected = detect(db, route)
    assert detected["status"] == "success" and detected["wall_plane"] is None
    assert db.connection.execute("SELECT count(*) FROM holds WHERE route_id = %s", (route.route_id,)).fetchone()[0] == len(LADDER)


@pytest.mark.skipif(
    not all((APP / "resources" / m).is_file() for m in ("holds_seg.onnx", "moge-2-vits-normal.onnx")) or not REAL_PHOTO.is_file(),
    reason="the real hold and depth models, or the real photo, are missing",
)
def test_real_models_on_a_real_photo_never_fail_the_detection(db: PostgreSQL, storage: RustFS, monkeypatch):
    """A communication photo (climber in the foreground, no empty route): the plane may well not be found."""
    from worker import runtime

    monkeypatch.undo()  # back to the real getters of the module
    runtime.get_depth_estimator.cache_clear()
    runtime.get_hold_segmenter.cache_clear()
    monkeypatch.setattr(holds_mod, "get_depth_estimator", runtime.get_depth_estimator)
    monkeypatch.setattr(holds_mod, "get_hold_segmenter", runtime.get_hold_segmenter)
    route = producer.seed_route(str(REAL_PHOTO), db, storage)
    try:
        detected = detect(db, route, gravity=[0.0, 1.0, 0.0])
        assert detected["status"] == "success", detected
        if detected["wall_plane"] is not None:
            WallPlane.model_validate(detected["wall_plane"])
        print(f"\nreal photo: wall_plane {'found' if detected['wall_plane'] else 'not found'}, angle {detected['wall_angle_deg']}")
    finally:
        db.connection.execute("DELETE FROM users WHERE id = %s", (route.user_id,))
        storage.client.delete_object(Bucket=storage.config.bucket, Key=route.object_key)
