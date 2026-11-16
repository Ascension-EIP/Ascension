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
from shared.models import AnalysisResult, Hints, Status

logger = logging.getLogger(__name__)

PROGRESS_RESULT_SAVED = 85
PROGRESS_MAX_RUNNING = 99


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
            "status = %s, progress = %s",
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
        self._update(job_id, "status = %s, error = %s", Status.FAILED.value, message)

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
            "status = %s, progress = %s",
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
            "status = %s, error = %s",
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
