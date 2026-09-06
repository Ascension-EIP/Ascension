# @date 2026-09-07
# @file interfaces.py
# @brief Abstract base classes and protocols for AI pipelines.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""Abstract interfaces and protocols for AI pipelines."""

from abc import ABC, abstractmethod
from typing import Any, Protocol, runtime_checkable

from src.core.models import ProgressCallback


class BasePipeline(ABC):
    """Abstract base class for all AI pipelines."""

    @property
    @abstractmethod
    def name(self) -> str:
        """Unique identifier for this pipeline (e.g. 'pose_analysis_2d')."""

    @abstractmethod
    def analyze(
        self,
        video_path: str,
        on_progress: ProgressCallback | None = None,
        **kwargs: Any,
    ) -> dict[str, Any]:
        """Execute video analysis and return biomechanical JSON-serializable dict."""


@runtime_checkable
class AdviceCapability(Protocol):
    """Protocol for pipelines capable of generating coaching advice."""

    def generate_advice(self, analysis_result: dict[str, Any]) -> str | None:
        """Generate coaching advice from analysis result using Gemini or an LLM."""
