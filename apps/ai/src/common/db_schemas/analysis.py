# @date 2026-11-01
# @file analysis.py
# @brief Pydantic models for the `analyses` table, its `result` and `hints` JSONB payloads.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""Pydantic model mirroring the `analyses` table.

The JSONB payloads (`AnalysisResult`, `Hints`) and the job statuses come from
`shared.models`, generated from `schemas/`. Only the table row and the DB-only
enums live here, plus the constraints quicktype cannot express (`priority`
between 1 and 5, no unknown key in `result`).

    result = AnalysisResult.model_validate(data)
    analysis = Analysis(video_id=..., result=result, status=Status.SUCCESS)
"""

from datetime import datetime
from enum import StrEnum
from typing import Any, Self
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator

from shared.models import AnalysisResult, Hints, Status


class AnalysisType(StrEnum):
    """`analysis_type` enum: which pipeline produced the analysis."""

    TWO_D = "2d"
    THREE_D = "3d"


class Visibility(StrEnum):
    """`visibility` enum: who is allowed to see the analysis."""

    PRIVATE = "private"
    FRIENDS = "friends"
    PUBLIC = "public"


class Analysis(BaseModel):
    """Row of the `analyses` table.

    Mirrors the `chk_analyses_progress`, `chk_analyses_completed` and
    `chk_analyses_failed` CHECK constraints, so an invalid row fails here
    instead of at the PostgreSQL boundary.
    """

    model_config = ConfigDict(from_attributes=True)

    id: UUID | None = None
    video_id: UUID
    type: AnalysisType = AnalysisType.TWO_D
    status: Status = Status.PENDING
    progress: int = Field(default=0, ge=0, le=100)
    result: AnalysisResult | None = None
    hints: Hints | None = None
    error: str | None = None
    processing_time_ms: int | None = None
    started_at: datetime | None = None
    completed_at: datetime | None = None
    visibility: Visibility = Visibility.PRIVATE
    created_at: datetime | None = None
    updated_at: datetime | None = None

    @field_validator("result", mode="before")
    @classmethod
    def forbid_unknown_result_keys(cls, value: Any) -> Any:
        """Reject unknown keys at every level of `result` (quicktype drops `additionalProperties: false`)."""
        if isinstance(value, dict):
            return AnalysisResult.model_validate(value, extra="forbid")
        return value

    @field_validator("hints")
    @classmethod
    def check_hint_priorities(cls, value: Hints | None) -> Hints | None:
        """Enforce the 1-5 `priority` range of the schema (quicktype drops it)."""
        if value is not None and any(not 1 <= h.priority <= 5 for h in value.items):
            raise ValueError("hint `priority` must be between 1 and 5")
        return value

    @model_validator(mode="after")
    def check_status_consistency(self) -> Self:
        """Enforce `chk_analyses_completed` and `chk_analyses_failed`."""
        if self.status == Status.SUCCESS and (
            self.result is None or self.completed_at is None
        ):
            raise ValueError(
                "a successful analysis requires both `result` and `completed_at`"
            )
        if self.status == Status.FAILED and self.error is None:
            raise ValueError("a failed analysis requires `error`")
        return self
