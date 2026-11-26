# @date 2026-11-24
# @file test_postgresql_routes.py
# @brief Hold detection operations of the PostgreSQL service (routes and holds tables).
# @project Ascension
# @author Livoooo <zarigu92@gmail.com>
# @copyright (c) 2026 Ascension
# @status done
import os
from unittest.mock import MagicMock
from uuid import uuid4

import psycopg
import pytest

from common.utils.errors import PermanentError, TransientError
from services.postgresql import PostgreSQL
from shared.models import HoldDetectResult, Status

HOLD = {
    "type": "unknown",
    "confidence": 0.9,
    "contour": {"points": [{"x": 1, "y": 2}, {"x": 5, "y": 2}, {"x": 5, "y": 6}], "bbox": {"x": 1, "y": 2, "w": 4, "h": 4}},
    "color": {"name": "blue", "rgb": [20, 60, 200], "distance": 3.2},
}
VOLUME = {**HOLD, "type": "volume", "color": None}
RESULT = HoldDetectResult.model_validate({"image_width": 4032, "image_height": 3024, "holds": [HOLD, VOLUME]})
URL = os.getenv("TEST_POSTGRES_URL")


def transactional(first_row=("r",)) -> tuple[PostgreSQL, MagicMock]:
    """Service on a simulated connection; returns it and the cursor used by the transaction."""
    connection = MagicMock(closed=False)
    cursor = connection.cursor.return_value.__enter__.return_value
    cursor.execute.return_value.fetchone.return_value = first_row
    db = PostgreSQL()
    db.connection = connection
    return db, cursor


def test_save_holds_updates_the_route_replaces_ai_holds_and_inserts_each_hold():
    db, cursor = transactional()
    db.save_holds("r", RESULT)
    statements = [c.args[0] for c in cursor.execute.call_args_list]
    assert statements[0].startswith("UPDATE routes SET image_width")
    assert cursor.execute.call_args_list[0].args[1] == (4032, 3024, 90, "r")
    assert "source = 'ai' AND corrected_at IS NULL" in statements[1]  # user corrections are kept
    assert [s.startswith("INSERT INTO holds") for s in statements[2:]] == [True, True]
    hold, volume = (c.args[1] for c in cursor.execute.call_args_list[2:])
    assert hold[1] == hold[4] == "unknown"  # current type and frozen prediction
    assert hold[5] == 0.9
    assert hold[3].obj == {"name": "blue", "rgb": [20, 60, 200], "distance": 3.2}
    assert volume[1] == "volume"
    assert volume[3] is None  # no colour measured


def test_save_holds_on_an_unknown_route_is_permanent():
    db, _cursor = transactional(first_row=None)
    with pytest.raises(PermanentError):
        db.save_holds("missing", RESULT)


def test_save_holds_retries_once_on_a_dropped_connection_then_is_transient():
    db, cursor = transactional()
    cursor.execute.side_effect = psycopg.OperationalError("server closed the connection")
    db.connect = lambda: db
    with pytest.raises(TransientError):
        db.save_holds("r", RESULT)
    assert cursor.execute.call_count == 2


def test_route_job_updates_target_the_routes_table():
    connection = MagicMock(closed=False)
    connection.execute.return_value.fetchone.return_value = ("r",)
    db = PostgreSQL()
    db.connection = connection
    db.update_route_progress("r", 150)
    sql, params = connection.execute.call_args.args
    assert sql.startswith("UPDATE routes SET")
    assert params == ("running", 99, "r")  # capped below 100
    db.fail_route("r", "Photo not found")
    assert connection.execute.call_args.args[1] == ("failed", "Photo not found", "r")


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
def route_id(db):
    """A fresh `pending` route; deleting its user cascades to the route and its holds."""
    name = f"t{uuid4().hex[:12]}"
    user = db.connection.execute(
        "INSERT INTO users (username, first_name, last_name, email, password_hash)"
        " VALUES (%s, 'T', 'T', %s, 'x') RETURNING id",
        (name, f"{name}@example.com"),
    ).fetchone()[0]
    route = db.connection.execute(
        "INSERT INTO routes (user_id, image_object_key, image_width, image_height) VALUES (%s, %s, 0, 0) RETURNING id",
        (user, name),
    ).fetchone()[0]
    yield str(route)
    db.connection.execute("DELETE FROM users WHERE id = %s", (user,))


@pytest.mark.integration
@pytest.mark.skipif(not URL, reason="TEST_POSTGRES_URL not set")
class TestRoutesAgainstDatabase:
    def holds(self, db, route_id):
        return db.connection.execute(
            "SELECT source, type, predicted_type, predicted_confidence, color->>'name', corrected_at IS NOT NULL"
            " FROM holds WHERE route_id = %s ORDER BY type",
            (route_id,),
        ).fetchall()

    def test_full_cycle_and_redelivery(self, db, route_id):
        assert db.get_route_status(route_id) == Status.PENDING
        db.mark_route_started(route_id)
        db.update_route_progress(route_id, 10)
        db.save_holds(route_id, RESULT)
        db.save_holds(route_id, RESULT)  # redelivered job: holds are replaced, not duplicated
        db.complete_route(route_id)
        status, progress, width, height, done = db.connection.execute(
            "SELECT status, progress, image_width, image_height, completed_at IS NOT NULL FROM routes WHERE id = %s",
            (route_id,),
        ).fetchone()
        assert (status, progress, width, height, done) == ("success", 100, 4032, 3024, True)
        rows = self.holds(db, route_id)
        assert [(r[0], r[1], r[2], r[4]) for r in rows] == [("ai", "volume", "volume", None), ("ai", "unknown", "unknown", "blue")]

    def test_user_corrections_survive_a_new_detection(self, db, route_id):
        db.save_holds(route_id, RESULT)
        db.connection.execute(
            "UPDATE holds SET type = 'jug', corrected_at = NOW() WHERE route_id = %s AND type = 'unknown'", (route_id,)
        )
        db.save_holds(route_id, RESULT)
        assert sorted(r[1] for r in self.holds(db, route_id)) == ["jug", "unknown", "volume"]

    def test_failure_needs_a_message(self, db, route_id):
        db.fail_route(route_id, "Photo not found")
        assert db.connection.execute("SELECT status, error FROM routes WHERE id = %s", (route_id,)).fetchone() == (
            "failed",
            "Photo not found",
        )

    def test_unknown_route(self, db):
        with pytest.raises(PermanentError):
            db.get_route_status(str(uuid4()))
        with pytest.raises(PermanentError):
            db.save_holds(str(uuid4()), RESULT)
