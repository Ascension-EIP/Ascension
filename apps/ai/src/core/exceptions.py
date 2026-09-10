# @date 2026-09-05
# @file exceptions.py
# @brief Domain and application exceptions for the Ascension AI service.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""Domain and application exceptions."""


class AscensionAIError(Exception):
    """Base exception for all Ascension AI application errors."""


class InferenceError(AscensionAIError):
    """Raised when an AI pipeline fails during inference."""


class VideoProcessingError(AscensionAIError):
    """Raised when OpenCV fails to read or write a video."""


class StorageError(AscensionAIError):
    """Raised when an S3 / MinIO operation fails."""


class DatabaseError(AscensionAIError):
    """Raised when a PostgreSQL operation fails."""


class BrokerError(AscensionAIError):
    """Raised when a RabbitMQ operation fails."""


class PipelineNotFoundError(AscensionAIError):
    """Raised when a requested AI pipeline is not registered."""
