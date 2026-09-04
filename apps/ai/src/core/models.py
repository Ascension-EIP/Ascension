# @date 2026-09-05
# @file models.py
# @brief Domain models and type definitions.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""Domain models and type definitions."""

from collections.abc import Callable
from dataclasses import dataclass
from typing import Any

ProgressCallback = Callable[[int], None]


@dataclass(frozen=True)
class JobPayload:
    """Incoming job payload from RabbitMQ."""

    job_id: str
    analysis_id: str
    video_url: str
    pipeline_name: str | None = None

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "JobPayload":
        """Build a JobPayload instance from a parsed JSON dictionary."""
        return cls(
            job_id=str(data.get("job_id", "unknown")),
            analysis_id=str(data.get("analysis_id", "")),
            video_url=str(data.get("video_url", "")),
            pipeline_name=data.get("pipeline") or data.get("pipeline_name") or data.get("engine"),
        )


@dataclass(frozen=True)
class CompletionEvent:
    """Outgoing completion event published to ascension.events."""

    job_id: str
    analysis_id: str
    status: str
    processing_time_ms: int

    def to_dict(self) -> dict[str, Any]:
        """Convert to dictionary for JSON serialization."""
        return {
            "job_id": self.job_id,
            "analysis_id": self.analysis_id,
            "status": self.status,
            "processing_time_ms": self.processing_time_ms,
        }
