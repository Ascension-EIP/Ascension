# @date 2026-11-25
# @file test_postgresql_ghosts.py
# @brief Ghost operations of the PostgreSQL service (ghosts, ghost_holds, routes and holds tables).
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
import json
import os
from unittest.mock import MagicMock
from uuid import uuid4

import pytest

from common.utils.errors import PermanentError
from services.postgresql import PostgreSQL
from shared.models import GhostMorphology, GhostPath, Status, WallPlane

URL = os.getenv("TEST_POSTGRES_URL")
WALL = WallPlane(focal_px=2500.0, homography=[[0.1, 0, 0], [0, -0.1, 50], [0, 0, 1]], inlier_ratio=0.93, model="m", angle_deg=5.0)
CONTOUR = {"points": [{"x": 1, "y": 2}, {"x": 5, "y": 2}, {"x": 5, "y": 6}], "bbox": {"x": 1, "y": 2, "w": 4, "h": 4}}
MORPHOLOGY = {"height_cm": 175, "arm_span_cm": 178, "constraints": [{"type": "injured", "zone": "left_hand"}]}
PATH = GhostPath.model_validate(
    {
        "image_width": 400,
        "image_height": 800,
        "steps": [
            {
                "index": 0,
                "holds": {"left_hand": "a"},
                "landmarks": {"nose": {"x": 1.0, "y": 2.0}},
                "center_of_mass": {"x": 1.0, "y": 2.0},
            }
        ],
    }
)


def service(**results) -> tuple[PostgreSQL, MagicMock]:
    """Service on a simulated connection; ``results`` maps a fragment of SQL to what the query returns."""
    connection = MagicMock(closed=False)

    def execute(sql, params=None):
        cursor = MagicMock()
        for fragment, rows in results.items():
            if fragment in sql:
                cursor.fetchone.return_value = rows[0] if rows else None
                cursor.fetchall.return_value = rows
        return cursor

    connection.execute.side_effect = execute
    db = PostgreSQL()
    db.connection = connection
    return db, connection


def test_ghost_job_updates_target_the_ghosts_table():
    db, connection = service(**{"UPDATE ghosts": [("g",)]})
    db.mark_ghost_started("g")
    sql, params = connection.execute.call_args.args
    assert sql.startswith("UPDATE ghosts SET") and "started_at = NOW()" in sql and params == ("started", "g")
    db.update_ghost_progress("g", 150)
    assert connection.execute.call_args.args[1] == ("running", 99, "g")
    db.fail_ghost("g", "Wall geometry missing")
    assert connection.execute.call_args.args[1] == ("failed", "Wall geometry missing", "g")


def test_complete_ghost_stores_the_path_and_the_status_together():
    db, connection = service(**{"UPDATE ghosts": [("g",)]})
    db.complete_ghost("g", PATH)
    sql, params = connection.execute.call_args.args
    assert "path = %s" in sql and "status = %s" in sql  # one statement: chk_ghosts_completed needs both
    assert "::INTEGER" in sql  # processing_time_ms is an integer
    assert params[0].obj["steps"][0]["holds"] == {"left_hand": "a"} and params[1:] == ("success", "g")


def test_get_ghost_input_reads_the_ghost_the_route_the_holds_and_the_selection():
    hold = ("h1", "unknown", CONTOUR, True, 2, None)
    db, _ = service(
        **{
            "FROM ghosts": [("r", MORPHOLOGY, 400, 800, True, WALL.model_dump(mode="json"))],
            "FROM holds": [hold, ("h2", "volume", CONTOUR, False, None, 1)],
            "FROM ghost_holds": [("h1",)],
        }
    )
    ghost = db.get_ghost_input("g")
    assert ghost.morphology == GhostMorphology.model_validate(MORPHOLOGY)
    assert (ghost.image_width, ghost.image_height, ghost.feet_free, ghost.wall) == (400, 800, True, WALL)
    assert ghost.holds == [
        {"id": "h1", "type": "unknown", "contour": CONTOUR, "usable": True, "start_limbs": 2, "finish_limbs": None},
        {"id": "h2", "type": "volume", "contour": CONTOUR, "usable": False, "start_limbs": None, "finish_limbs": 1},
    ]
    assert ghost.selected_ids == ["h1"]


def test_a_route_without_wall_gives_none():
    db, _ = service(**{"FROM ghosts": [("r", MORPHOLOGY, 400, 800, False, None)], "FROM holds": [], "FROM ghost_holds": []})
    assert db.get_ghost_input("g").wall is None


def test_an_unknown_ghost_is_permanent():
    db, _ = service(**{"FROM ghosts": []})
    with pytest.raises(PermanentError):
        db.get_ghost_input("g")


@pytest.mark.parametrize(
    "morphology, wall",
    [({"arm_span_cm": 178}, None), (MORPHOLOGY, {"homography": "nope"})],
    ids=["invalid-morphology", "invalid-wall"],
)
def test_stored_json_that_does_not_match_the_schema_is_permanent(morphology, wall):
    db, _ = service(**{"FROM ghosts": [("r", morphology, 400, 800, False, wall)]})
    with pytest.raises(PermanentError, match="invalid"):
        db.get_ghost_input("g")


# --- against a migrated database (moon run ai:e2e, or TEST_POSTGRES_URL) -------------------


@pytest.fixture
def db():
    database = PostgreSQL()
    database.setup_config()
    database.config.url = URL
    database.connect()
    yield database
    database.connection.close()


@pytest.fixture
def ghost(db):
    """A `pending` ghost on a route with a wall and two holds; deleting its user cascades to everything."""
    name = f"t{uuid4().hex[:12]}"
    execute = db.connection.execute
    user = execute(
        "INSERT INTO users (username, first_name, last_name, email, password_hash) VALUES (%s, 'T', 'T', %s, 'x') RETURNING id",
        (name, f"{name}@example.com"),
    ).fetchone()[0]
    route = execute(
        "INSERT INTO routes (user_id, image_object_key, image_width, image_height, feet_free, wall_plane)"
        " VALUES (%s, %s, 400, 800, TRUE, %s::jsonb) RETURNING id",
        (user, name, WALL.model_dump_json()),
    ).fetchone()[0]
    ids = []
    for kind, usable, start in (("unknown", True, 2), ("volume", False, None)):
        ids.append(
            execute(
                "INSERT INTO holds (route_id, source, type, usable, contour, start_limbs, predicted_type, predicted_confidence)"
                " VALUES (%s, 'ai', %s, %s, %s::jsonb, %s, %s, 0.9) RETURNING id",
                (route, kind, usable, json.dumps(CONTOUR), start, kind),
            ).fetchone()[0]
        )
    ghost_id = execute(
        "INSERT INTO ghosts (route_id, user_id, morphology) VALUES (%s, %s, %s::jsonb) RETURNING id",
        (route, user, json.dumps(MORPHOLOGY)),
    ).fetchone()[0]
    execute("INSERT INTO ghost_holds (ghost_id, hold_id, position) VALUES (%s, %s, 1)", (ghost_id, ids[0]))
    yield str(ghost_id), [str(i) for i in ids]
    execute("DELETE FROM users WHERE id = %s", (user,))


@pytest.mark.integration
@pytest.mark.skipif(not URL, reason="TEST_POSTGRES_URL not set")
class TestGhostsAgainstDatabase:
    def test_full_cycle_and_redelivery(self, db, ghost):
        ghost_id, _ = ghost
        assert db.get_ghost_status(ghost_id) == Status.PENDING
        db.mark_ghost_started(ghost_id)
        db.update_ghost_progress(ghost_id, 30)
        db.complete_ghost(ghost_id, PATH)
        status, progress, path, done, ms = db.connection.execute(
            "SELECT status, progress, path, completed_at IS NOT NULL, processing_time_ms FROM ghosts WHERE id = %s", (ghost_id,)
        ).fetchone()
        assert (status, progress, done) == ("success", 100, True) and isinstance(ms, int)
        assert GhostPath.model_validate(path) == PATH
        db.mark_ghost_started(ghost_id)  # a redelivered job starts again from a clean row
        assert db.connection.execute("SELECT status, completed_at FROM ghosts WHERE id = %s", (ghost_id,)).fetchone() == ("started", None)

    def test_input_of_the_job(self, db, ghost):
        ghost_id, holds = ghost
        data = db.get_ghost_input(ghost_id)
        assert data.morphology.height_cm == 175 and data.feet_free and data.wall == WALL
        assert (data.image_width, data.image_height) == (400, 800)
        assert sorted(h["id"] for h in data.holds) == sorted(holds)
        marked = {h["id"]: h for h in data.holds}
        assert marked[holds[0]]["start_limbs"] == 2 and marked[holds[1]]["usable"] is False
        assert data.selected_ids == [holds[0]]

    def test_failure_needs_a_message(self, db, ghost):
        db.fail_ghost(ghost[0], "No beta")
        assert db.connection.execute("SELECT status, error FROM ghosts WHERE id = %s", (ghost[0],)).fetchone() == ("failed", "No beta")

    def test_unknown_ghost(self, db):
        with pytest.raises(PermanentError):
            db.get_ghost_status(str(uuid4()))
        with pytest.raises(PermanentError):
            db.get_ghost_input(str(uuid4()))
