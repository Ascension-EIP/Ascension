# @date 2026-11-01
# @file test_postgresql.py
# @brief Tests for the PostgreSQL job operations: mocked connection, then a real migrated database.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
import os
from datetime import UTC, datetime
from unittest.mock import MagicMock
from uuid import uuid4

import psycopg
import pytest

from common.utils.errors import PermanentError, TransientError
from services.postgresql import PostgreSQL
from shared.models import AnalysisResult, Hints, Status

RESULT = AnalysisResult.model_validate(
    {"fps": 30.0, "width": 1080, "height": 1920, "frames": []}
)
HINTS = Hints.model_validate(
    {
        "summary": "s",
        "items": [
            {"category": "technique", "priority": 1, "title": "t", "description": "d"}
        ],
        "model": "m",
        "generated_at": datetime(2026, 10, 30, tzinfo=UTC),
    }
)
URL = os.getenv("TEST_POSTGRES_URL")


def with_connection(connection) -> PostgreSQL:
    db = PostgreSQL()
    db.connection = connection
    return db


def test_update_progress_is_capped_below_100():
    connection = MagicMock(closed=False)
    connection.execute.return_value.fetchone.return_value = ("id",)
    with_connection(connection).update_progress("job", 100)
    assert connection.execute.call_args.args[1][1] == 99


def test_reconnects_when_connection_is_closed():
    fresh = MagicMock(closed=False)
    fresh.execute.return_value.fetchone.return_value = (Status.RUNNING.value,)
    db = with_connection(MagicMock(closed=True))
    db.connect = lambda: setattr(db, "connection", fresh) or db
    assert db.get_status("job") == Status.RUNNING


def test_dropped_connection_becomes_transient_error():
    connection = MagicMock(closed=False)
    connection.execute.side_effect = psycopg.OperationalError(
        "server closed the connection"
    )
    db = with_connection(connection)
    db.connect = lambda: db
    with pytest.raises(TransientError):
        db.get_status("job")
    assert connection.execute.call_count == 2


@pytest.fixture
def db():
    database = PostgreSQL()
    database.config = None
    database.setup_config()
    database.config.url = URL
    database.connect()
    yield database
    database.connection.close()


@pytest.fixture
def job_id(db):
    """A fresh `pending` analysis; deleting its user cascades to the video and the analysis."""
    name = f"t{uuid4().hex[:12]}"
    user = db.connection.execute(
        "INSERT INTO users (username, first_name, last_name, email, password_hash)"
        " VALUES (%s, 'T', 'T', %s, 'x') RETURNING id",
        (name, f"{name}@example.com"),
    ).fetchone()[0]
    video = db.connection.execute(
        "INSERT INTO videos (user_id, object_key, content_type) VALUES (%s, %s, 'video/mp4') RETURNING id",
        (user, name),
    ).fetchone()[0]
    analysis = db.connection.execute(
        "INSERT INTO analyses (video_id) VALUES (%s) RETURNING id", (video,)
    ).fetchone()[0]
    yield str(analysis)
    db.connection.execute("DELETE FROM users WHERE id = %s", (user,))


def row(db, job_id):
    return db.connection.execute(
        "SELECT status, progress, result IS NOT NULL, hints IS NOT NULL, error, started_at, completed_at,"
        " processing_time_ms FROM analyses WHERE id = %s",
        (job_id,),
    ).fetchone()


@pytest.mark.integration
@pytest.mark.skipif(not URL, reason="TEST_POSTGRES_URL not set")
class TestAgainstDatabase:
    def test_full_cycle(self, db, job_id):
        assert db.get_status(job_id) == Status.PENDING
        db.mark_started(job_id)
        assert row(db, job_id)[:2] == ("started", 0)
        db.update_progress(job_id, 40)
        assert row(db, job_id)[:2] == ("running", 40)
        db.save_result(job_id, RESULT)
        status, progress, has_result, *_ = row(db, job_id)
        assert (status, progress, has_result) == ("running", 85, True)
        assert db.get_result(job_id) == RESULT
        db.save_hints(job_id, HINTS)
        assert row(db, job_id)[3] is True
        db.complete(job_id)
        status, progress, _, _, error, started_at, completed_at, elapsed = row(
            db, job_id
        )
        assert (status, progress, error) == ("success", 100, None)
        assert started_at and completed_at and elapsed.total_seconds() >= 0

    def test_complete_without_result_violates_check(self, db, job_id):
        db.mark_started(job_id)
        with pytest.raises(PermanentError, match="chk_analyses_completed"):
            db.complete(job_id)
        assert db.get_status(job_id) == Status.STARTED

    def test_fail_sets_error(self, db, job_id):
        db.fail(job_id, "video is corrupted")
        assert row(db, job_id)[:2] == ("failed", 0)
        assert row(db, job_id)[4] == "video is corrupted"

    def test_get_result_without_result(self, db, job_id):
        with pytest.raises(PermanentError):
            db.get_result(job_id)

    def test_hints_can_be_rewritten_on_a_successful_analysis(self, db, job_id):
        db.mark_started(job_id)
        db.save_result(job_id, RESULT)
        db.complete(job_id)
        db.save_hints(job_id, HINTS)
        assert row(db, job_id)[:2] == ("success", 100)

    def test_mark_started_resets_a_failed_job(self, db, job_id):
        db.fail(job_id, "boom")
        db.mark_started(job_id)
        assert row(db, job_id)[4] is None

    def test_unknown_or_invalid_job_id(self, db):
        for bad in (str(uuid4()), "not-a-uuid"):
            for call in (
                db.get_status,
                db.get_result,
                db.mark_started,
                lambda j: db.fail(j, "x"),
            ):
                with pytest.raises(PermanentError):
                    call(bad)
