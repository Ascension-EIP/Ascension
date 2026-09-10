# @date 2026-09-06
# @file database.py
# @brief PostgreSQL repository for saving analyses results and progress.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""PostgreSQL repository for analyses."""

import json
import logging
from datetime import datetime, timezone
from typing import Any

import psycopg2
from psycopg2.extensions import connection as PgConnection

from src.config.settings import DatabaseSettings
from src.core.exceptions import DatabaseError

logger = logging.getLogger("ai-worker.db")


class AnalysisRepository:
    """Repository handling database updates for analyses."""

    def __init__(self, settings: DatabaseSettings):
        self.settings = settings

    def get_connection(self) -> PgConnection:
        """Create and return a new PostgreSQL connection."""
        try:
            if self.settings.db_url:
                return psycopg2.connect(self.settings.db_url)
            return psycopg2.connect(
                host=self.settings.host,
                port=self.settings.port,
                user=self.settings.user,
                password=self.settings.password,
                dbname=self.settings.db,
            )
        except psycopg2.Error as e:
            raise DatabaseError(f"Failed to connect to PostgreSQL: {e}") from e

    def update_status(self, conn: PgConnection, analysis_id: str, status: str) -> None:
        """Update analysis status."""
        try:
            with conn.cursor() as cur:
                cur.execute(
                    "UPDATE analyses SET status = %s, updated_at = NOW() WHERE id = %s",
                    (status, analysis_id),
                )
            conn.commit()
        except psycopg2.Error as e:
            conn.rollback()
            raise DatabaseError(f"Failed to update analysis status to {status}: {e}") from e

    def update_progress(self, conn: PgConnection, analysis_id: str, progress: int) -> None:
        """Update analysis real-time progress (0–99)."""
        try:
            with conn.cursor() as cur:
                cur.execute(
                    "UPDATE analyses SET progress = %s, updated_at = NOW() WHERE id = %s",
                    (progress, analysis_id),
                )
            conn.commit()
        except psycopg2.Error as e:
            conn.rollback()
            logger.warning("Failed to update progress for analysis %s: %s", analysis_id, e)

    def save_completed(
        self,
        conn: PgConnection,
        analysis_id: str,
        result: dict[str, Any],
        processing_time: int,
        hints: str | None = None,
    ) -> None:
        """Save successful analysis completion."""
        try:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    UPDATE analyses
                       SET status          = 'completed',
                           result          = %s,
                           hints           = %s,
                           processing_time = %s,
                           completed_at    = %s,
                           progress        = 100,
                           updated_at      = NOW()
                     WHERE id = %s
                    """,
                    (
                        json.dumps(result),
                        hints,
                        processing_time,
                        datetime.now(timezone.utc),
                        analysis_id,
                    ),
                )
            conn.commit()
            logger.info("Saved completed analysis %s in PostgreSQL", analysis_id)
        except psycopg2.Error as e:
            conn.rollback()
            raise DatabaseError(f"Failed to save completed analysis {analysis_id}: {e}") from e

    def mark_failed(
        self,
        conn: PgConnection,
        analysis_id: str,
        error: str | None = None,
    ) -> None:
        """Mark analysis as failed."""
        try:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    UPDATE analyses
                       SET status     = 'failed',
                           error      = %s,
                           updated_at = NOW()
                     WHERE id = %s
                    """,
                    (error, analysis_id),
                )
            conn.commit()
            logger.info("Marked analysis %s as failed in PostgreSQL", analysis_id)
        except Exception as e:
            conn.rollback()
            logger.warning("Could not mark analysis %s as failed: %s", analysis_id, e)

