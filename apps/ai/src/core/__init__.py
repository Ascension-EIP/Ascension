# @date 2026-09-07
# @file __init__.py
# @brief Core domain exports.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""Core domain models, interfaces, and exceptions."""

from src.core.exceptions import (
    AscensionAIError,
    BrokerError,
    DatabaseError,
    InferenceError,
    PipelineNotFoundError,
    StorageError,
    VideoProcessingError,
)
from src.core.interfaces import AdviceCapability, BasePipeline
from src.core.models import CompletionEvent, JobPayload, ProgressCallback

__all__ = [
    "AdviceCapability",
    "AscensionAIError",
    "BasePipeline",
    "BrokerError",
    "CompletionEvent",
    "DatabaseError",
    "InferenceError",
    "JobPayload",
    "PipelineNotFoundError",
    "ProgressCallback",
    "StorageError",
    "VideoProcessingError",
]
