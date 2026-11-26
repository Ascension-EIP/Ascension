# @date 2026-11-01
# @file postgresql.py
# @brief File description.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
import logging
import os
from typing import Any, Self

import psycopg
from psycopg import Connection
from psycopg.types.json import Jsonb
from pydantic import ValidationError

from common.models.database import DatabaseModel
from common.utils.errors import PermanentError, TransientError, throw_if_none
from shared.models import AnalysisResult, Hints, HoldDetectResult, Status

logger = logging.getLogger(__name__)

PROGRESS_RESULT_SAVED = 85
PROGRESS_MAX_RUNNING = 99
PROGRESS_HOLDS_SAVED = 90

_SET_PROGRESS = "status = %s, progress = %s"
_SET_FAILED = "status = %s, error = %s"

_INSERT_HOLD = (
    "INSERT INTO holds (route_id, source, type, contour, color,"
    " predicted_type, predicted_confidence, predicted_contour, predicted_color)"
    " VALUES (%s, 'ai', %s, %s, %s, %s, %s, %s, %s)"
)


class PostgreSQL:
    """Connection to PostgreSQL and the job operations on `analyses` and `advices`.

    The connection is in autocommit mode: each call is one atomic statement and
    no transaction stays open while a job runs. For the analysis methods `job_id`
    is `analyses.id`; for the `*_advice` methods it is `advices.id`, which is the
    id of the video (one advice per video).
    """

    def __init__(self):
        self.config: DatabaseModel | None = None
        self.connection: Connection | None = None

    def setup_config(self) -> Self:
        self.config = DatabaseModel(
            url=os.getenv("POSTGRES_DB_URL")
            or "",  # optional: built from the parts below
            host=os.getenv("POSTGRES_HOST", "localhost"),
            port=int(os.getenv("POSTGRES_PORT", "5432")),
            user=os.getenv("POSTGRES_USER") or "ascension",
            password=os.getenv("POSTGRES_PASSWORD") or "ascension",
            name=os.getenv("POSTGRES_DB") or "ascension",
        )
        throw_if_none(self.config)
        return self

    def connect(self) -> Self:
        if not self.config:
            self.setup_config()

        url = self.config.url or (
            f"postgresql://{self.config.user}:{self.config.password}"
            f"@{self.config.host}:{self.config.port}/{self.config.name}"
        )
        self.connection = psycopg.connect(url, autocommit=True)
        return self

    def _execute(self, sql: str, params: tuple, job_id: str) -> tuple:
        """Runs one statement that returns a row (SELECT or UPDATE ... RETURNING).

        Reconnects once if the connection was closed, for instance after the
        minutes a MediaPipe run keeps it idle.

        Raises:
            TransientError: The database is unreachable.
            PermanentError: Unknown `job_id`, invalid id, or a violated constraint.
        """
        for attempt in range(2):
            try:
                if self.connection is None or self.connection.closed:
                    self.connect()
                row = self.connection.execute(sql, params).fetchone()
                break
            except psycopg.OperationalError as error:
                if self.connection is not None:
                    self.connection.close()
                if attempt:
                    raise TransientError(f"database unavailable: {error}") from error
                logger.warning("database connection lost, reconnecting: %s", error)
            except (psycopg.DataError, psycopg.IntegrityError) as error:
                raise PermanentError(f"job {job_id}: {error}") from error
        if row is None:
            raise PermanentError(f"job {job_id}: no such row")
        return row

    def _transaction(self, job_id: str, statements: list[tuple[str, tuple]]) -> None:
        """Runs several statements in one transaction; the first one must return a row.

        Same reconnection and error mapping as `_execute`. Nothing is written if a
        statement fails.

        Raises:
            TransientError: The database is unreachable.
            PermanentError: The first statement matched no row, or a constraint is violated.
        """
        for attempt in range(2):
            try:
                if self.connection is None or self.connection.closed:
                    self.connect()
                self._run_statements(job_id, statements)
                return
            except psycopg.OperationalError as error:
                if self.connection is not None:
                    self.connection.close()
                if attempt:
                    raise TransientError(f"database unavailable: {error}") from error
                logger.warning("database connection lost, reconnecting: %s", error)
            except (psycopg.DataError, psycopg.IntegrityError) as error:
                raise PermanentError(f"job {job_id}: {error}") from error

    def _run_statements(self, job_id: str, statements: list[tuple[str, tuple]]) -> None:
        """Body of `_transaction`: rolled back as a whole when anything raises."""
        first, *rest = statements
        with self.connection.transaction(), self.connection.cursor() as cursor:
            if cursor.execute(*first).fetchone() is None:
                raise PermanentError(f"job {job_id}: no such row")
            for sql, params in rest:
                cursor.execute(sql, params)

    def _update(
        self, job_id: str, assignments: str, *params: Any, table: str = "analyses"
    ) -> None:
        self._execute(
            f"UPDATE {table} SET {assignments} WHERE id = %s RETURNING id",
            (*params, job_id),
            job_id,
        )

    def mark_started(self, job_id: str) -> None:
        """Takes the job: resets the state a previous delivery may have left."""
        self._update(
            job_id,
            "status = %s, progress = 0, started_at = NOW(), error = NULL,"
            " completed_at = NULL, processing_time_ms = NULL",
            Status.STARTED.value,
        )

    def update_progress(self, job_id: str, progress: int) -> None:
        """Sets `running` and the progress, capped at 99 (100 is `complete`)."""
        self._update(
            job_id,
            _SET_PROGRESS,
            Status.RUNNING.value,
            max(0, min(progress, PROGRESS_MAX_RUNNING)),
        )

    def save_result(self, job_id: str, result: AnalysisResult) -> None:
        """Stores `result` and sets progress to 85; the status is unchanged."""
        payload = Jsonb(result.model_dump(mode="json", exclude_none=True))
        self._update(
            job_id, "result = %s, progress = %s", payload, PROGRESS_RESULT_SAVED
        )

    def get_result(self, job_id: str) -> AnalysisResult:
        """Reads and validates `result`.

        Raises:
            PermanentError: Unknown job, `result` is NULL, or it does not match the schema.
        """
        (value,) = self._execute(
            "SELECT result FROM analyses WHERE id = %s", (job_id,), job_id
        )
        if value is None:
            raise PermanentError(f"job {job_id}: no result stored")
        try:
            return AnalysisResult.model_validate(value)
        except ValidationError as error:
            raise PermanentError(f"job {job_id}: stored result is invalid") from error

    def complete(self, job_id: str) -> None:
        """Ends the job with `success`; `chk_analyses_completed` requires a stored `result`."""
        self._update(
            job_id,
            "status = %s, progress = 100, completed_at = NOW(),"
            " processing_time_ms = NOW() - started_at",
            Status.SUCCESS.value,
        )

    def fail(self, job_id: str, message: str) -> None:
        """Ends the job with `failed`; `message` must be short, without traceback."""
        self._update(job_id, _SET_FAILED, Status.FAILED.value, message)

    def get_status(self, job_id: str) -> Status:
        """Returns the current status (the handler skips a job already in `success`)."""
        (value,) = self._execute(
            "SELECT status FROM analyses WHERE id = %s", (job_id,), job_id
        )
        return Status(value)

    def get_video_result(self, video_id: str) -> AnalysisResult:
        """Reads and validates the `result` of the latest successful analysis of a video.

        Raises:
            PermanentError: No finished analysis for this video, or `result` does not match the schema.
        """
        (value,) = self._execute(
            "SELECT result FROM analyses WHERE video_id = %s AND status = %s"
            " AND result IS NOT NULL ORDER BY created_at DESC LIMIT 1",
            (video_id, Status.SUCCESS.value),
            video_id,
        )
        try:
            return AnalysisResult.model_validate(value)
        except ValidationError as error:
            raise PermanentError(f"video {video_id}: stored result is invalid") from error

    def mark_advice_started(self, video_id: str) -> None:
        """Takes the advice job: resets the state a previous delivery may have left."""
        self._update(
            video_id,
            "status = %s, progress = 0, started_at = NOW(), error = NULL, result = NULL,"
            " completed_at = NULL, processing_time_ms = NULL",
            Status.STARTED.value,
            table="advices",
        )

    def update_advice_progress(self, video_id: str, progress: int) -> None:
        """Sets `running` and the advice progress, capped at 99 (100 is `complete_advice`)."""
        self._update(
            video_id,
            _SET_PROGRESS,
            Status.RUNNING.value,
            max(0, min(progress, PROGRESS_MAX_RUNNING)),
            table="advices",
        )

    def complete_advice(self, video_id: str, hints: Hints) -> None:
        """Stores `hints` as the `result` and ends the advice with `success`."""
        self._update(
            video_id,
            "result = %s, status = %s, progress = 100, completed_at = NOW(),"
            " processing_time_ms = NOW() - started_at",
            Jsonb(hints.model_dump(mode="json", exclude_none=True)),
            Status.SUCCESS.value,
            table="advices",
        )

    def fail_advice(self, video_id: str, message: str) -> None:
        """Ends the advice with `failed`; `message` must be short, without traceback."""
        self._update(
            video_id,
            _SET_FAILED,
            Status.FAILED.value,
            message,
            table="advices",
        )

    def get_advice_status(self, video_id: str) -> Status:
        """Returns the current advice status (the handler skips an advice already in `success`)."""
        (value,) = self._execute(
            "SELECT status FROM advices WHERE id = %s", (video_id,), video_id
        )
        return Status(value)

    # Hold detection: `route_id` is `routes.id`, the job id of `holds.detect.requested`.

    def get_route_status(self, route_id: str) -> Status:
        """Returns the detection status (the handler skips a route already in `success`)."""
        (value,) = self._execute(
            "SELECT status FROM routes WHERE id = %s", (route_id,), route_id
        )
        return Status(value)

    def mark_route_started(self, route_id: str) -> None:
        """Takes the detection job: resets the state a previous delivery may have left."""
        self._update(
            route_id,
            "status = %s, progress = 0, started_at = NOW(), error = NULL,"
            " completed_at = NULL, processing_time_ms = NULL",
            Status.STARTED.value,
            table="routes",
        )

    def update_route_progress(self, route_id: str, progress: int) -> None:
        """Sets `running` and the progress, capped at 99 (100 is `complete_route`)."""
        self._update(
            route_id,
            _SET_PROGRESS,
            Status.RUNNING.value,
            max(0, min(progress, PROGRESS_MAX_RUNNING)),
            table="routes",
        )

    def save_holds(self, route_id: str, result: HoldDetectResult) -> None:
        """Replaces the AI holds of the route with ``result``, in one transaction.

        Holds drawn or corrected by the user are kept, so a redelivered job never
        duplicates holds nor loses a correction. The real photo size replaces the one
        the server stored, since every hold coordinate is relative to it.
        """
        statements: list[tuple[str, tuple]] = [
            (
                (
                    "UPDATE routes SET image_width = %s, image_height = %s, progress = %s"
                    " WHERE id = %s RETURNING id"
                ),
                (result.image_width, result.image_height, PROGRESS_HOLDS_SAVED, route_id),
            ),
            (
                "DELETE FROM holds WHERE route_id = %s AND source = 'ai' AND corrected_at IS NULL",
                (route_id,),
            ),
        ]
        for hold in result.holds:
            contour = Jsonb(hold.contour.model_dump(mode="json"))
            color = Jsonb(hold.color.model_dump(mode="json")) if hold.color else None
            statements.append(
                (
                    _INSERT_HOLD,
                    (route_id, hold.type.value, contour, color, hold.type.value, hold.confidence, contour, color),
                )
            )
        self._transaction(route_id, statements)

    def complete_route(self, route_id: str) -> None:
        """Ends the detection with `success` (`processing_time_ms` is an integer here)."""
        self._update(
            route_id,
            "status = %s, progress = 100, completed_at = NOW(),"
            " processing_time_ms = (EXTRACT(EPOCH FROM NOW() - started_at) * 1000)::INTEGER",
            Status.SUCCESS.value,
            table="routes",
        )

    def fail_route(self, route_id: str, message: str) -> None:
        """Ends the detection with `failed`; `message` must be short, without traceback."""
        self._update(
            route_id, _SET_FAILED, Status.FAILED.value, message, table="routes"
        )
