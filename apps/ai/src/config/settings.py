# @date 2026-09-07
# @file settings.py
# @brief Configuration dataclasses for the Ascension AI service.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""Configuration dataclasses."""

from dataclasses import asdict, dataclass
from typing import Any

from src.config.security import mask_dict


@dataclass(frozen=True)
class DatabaseSettings:
    """PostgreSQL database settings."""

    db_url: str | None
    host: str
    port: int
    user: str
    password: str
    db: str


@dataclass(frozen=True)
class StorageSettings:
    """MinIO / S3 object storage settings."""

    endpoint: str
    access_key: str
    secret_key: str
    bucket: str
    region: str = "us-east-1"


@dataclass(frozen=True)
class BrokerSettings:
    """RabbitMQ message broker settings."""

    host: str
    port: int
    user: str
    password: str
    retry_delay: int
    max_retries: int
    queue_skeleton: str
    exchange_events: str


@dataclass(frozen=True)
class AISettings:
    """AI pipelines and models configuration."""

    active_pose_pipeline: str
    gemini_api_key: str | None
    gemini_model: str
    mediapipe_model_path: str
    sam3d_checkpoint_path: str
    sam3d_mhr_path: str


@dataclass(frozen=True)
class WorkerSettings:
    """Worker process configuration."""

    log_level: str
    pid_file: str


@dataclass(frozen=True)
class Settings:
    """Global application settings aggregating all configurations."""

    database: DatabaseSettings
    storage: StorageSettings
    broker: BrokerSettings
    ai: AISettings
    worker: WorkerSettings

    def to_masked_dict(self) -> dict[str, Any]:
        """Return a dictionary representation with all sensitive fields masked."""
        raw = {
            "database": asdict(self.database),
            "storage": asdict(self.storage),
            "broker": asdict(self.broker),
            "ai": asdict(self.ai),
            "worker": asdict(self.worker),
        }
        return mask_dict(raw)
