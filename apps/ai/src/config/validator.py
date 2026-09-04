# @date 2026-09-05
# @file validator.py
# @brief Environment variables validator and settings loader.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""Environment variables validator and configuration loader."""

import os
from pathlib import Path
from dotenv import load_dotenv

from src.config.exceptions import InvalidEnvVarValueError, MissingRequiredEnvVarError
from src.config.settings import (
    AISettings,
    BrokerSettings,
    DatabaseSettings,
    Settings,
    StorageSettings,
    WorkerSettings,
)

_PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent.parent.parent


def _ensure_env_loaded() -> None:
    """Load .env from repository root if present and not already loaded."""
    env_file = _PROJECT_ROOT / ".env"
    if env_file.is_file():
        load_dotenv(dotenv_path=env_file, override=False)
    local_env = Path(__file__).resolve().parent.parent.parent / ".env"
    if local_env.is_file():
        load_dotenv(dotenv_path=local_env, override=False)


def _get_int(key: str, default: int) -> int:
    """Parse an integer environment variable with fallback."""
    raw = os.getenv(key)
    if raw is None or raw.strip() == "":
        return default
    try:
        return int(raw.strip())
    except ValueError as err:
        raise InvalidEnvVarValueError(
            f"Environment variable {key} must be an integer, got: {raw!r}"
        ) from err


def load_ai_settings(load_env: bool = True) -> AISettings:
    """Load settings needed specifically for AI pipelines (usable standalone)."""
    if load_env:
        _ensure_env_loaded()
    base_dir = Path(__file__).resolve().parent.parent.parent
    default_model_path = str(base_dir / "pose_landmarker.task")
    default_ckpt = str(base_dir / "checkpoints/sam-3d-body-dinov3/model.ckpt")
    default_mhr = str(base_dir / "checkpoints/sam-3d-body-dinov3/assets/mhr_model.pt")

    return AISettings(
        active_pose_pipeline=os.getenv("ACTIVE_POSE_PIPELINE", "pose_analysis_2d"),
        gemini_api_key=os.getenv("GEMINI_API_KEY"),
        gemini_model=os.getenv("GEMINI_MODEL", "gemini-3.1-flash-lite"),
        mediapipe_model_path=default_model_path,
        sam3d_checkpoint_path=default_ckpt,
        sam3d_mhr_path=default_mhr,
    )


def load_settings(standalone: bool = False, load_env: bool = True) -> Settings:
    """Load and validate all settings for the AI worker service.

    Args:
        standalone: If True, skip strict database/storage/broker validation
                    (for local AI dev without infrastructure).
        load_env: If True, load .env file from disk if present.

    Raises:
        MissingRequiredEnvVarError: If mandatory environment variables are missing.
        InvalidEnvVarValueError: If an environment variable has an invalid type/value.
    """
    if load_env:
        _ensure_env_loaded()
    ai_settings = load_ai_settings(load_env=load_env)

    base_dir = Path(__file__).resolve().parent.parent.parent
    pid_file = str(base_dir / "worker.pid")
    log_level = os.getenv("LOG_LEVEL", "INFO").upper()
    worker_settings = WorkerSettings(log_level=log_level, pid_file=pid_file)

    missing_mandatory: list[str] = []

    # 1. Database validation
    db_url = os.getenv("POSTGRES_DB_URL")
    db_user = os.getenv("POSTGRES_USER")
    db_password = os.getenv("POSTGRES_PASSWORD")
    db_name = os.getenv("POSTGRES_DB")

    if not standalone:
        if not db_url:
            if not db_user:
                missing_mandatory.append("POSTGRES_USER (or POSTGRES_DB_URL)")
            if not db_password:
                missing_mandatory.append("POSTGRES_PASSWORD (or POSTGRES_DB_URL)")
            if not db_name:
                missing_mandatory.append("POSTGRES_DB (or POSTGRES_DB_URL)")

    database_settings = DatabaseSettings(
        db_url=db_url,
        host=os.getenv("POSTGRES_HOST", "localhost"),
        port=_get_int("POSTGRES_PORT", 5432),
        user=db_user or "ascension",
        password=db_password or "ascension",
        db=db_name or "ascension",
    )

    # 2. Storage validation (MinIO / S3)
    endpoint = os.getenv("MINIO_ENDPOINT")
    if not endpoint:
        minio_host = os.getenv("MINIO_HOST", "localhost")
        minio_port = os.getenv("MINIO_PORT", "9000")
        endpoint = f"http://{minio_host}:{minio_port}"

    access_key = (
        os.getenv("MINIO_ROOT_USER")
        or os.getenv("MINIO_ID")
        or os.getenv("AWS_ACCESS_KEY_ID")
    )
    secret_key = (
        os.getenv("MINIO_ROOT_PASSWORD")
        or os.getenv("MINIO_SECRET")
        or os.getenv("AWS_SECRET_ACCESS_KEY")
    )

    if not standalone:
        if not access_key:
            missing_mandatory.append("MINIO_ROOT_USER or MINIO_ID")
        if not secret_key:
            missing_mandatory.append("MINIO_ROOT_PASSWORD or MINIO_SECRET")

    storage_settings = StorageSettings(
        endpoint=endpoint,
        access_key=access_key or "ascension",
        secret_key=secret_key or "ascension",
        bucket=os.getenv("MINIO_BUCKET", "videos"),
    )

    # 3. Broker validation (RabbitMQ)
    broker_user = (
        os.getenv("RABBITMQ_DEFAULT_USER")
        or os.getenv("RABBITMQ_USER")
    )
    broker_pass = (
        os.getenv("RABBITMQ_DEFAULT_PASS")
        or os.getenv("RABBITMQ_PASS")
    )

    if not standalone:
        if not broker_user:
            missing_mandatory.append("RABBITMQ_DEFAULT_USER or RABBITMQ_USER")
        if not broker_pass:
            missing_mandatory.append("RABBITMQ_DEFAULT_PASS or RABBITMQ_PASS")

    broker_settings = BrokerSettings(
        host=os.getenv("RABBITMQ_HOST", "localhost"),
        port=_get_int("RABBITMQ_PORT", 5672),
        user=broker_user or "ascension",
        password=broker_pass or "ascension",
        retry_delay=_get_int("RABBITMQ_RETRY_DELAY", 5),
        max_retries=_get_int("RABBITMQ_MAX_RETRIES", 12),
        queue_skeleton="ascension.skeleton",
        exchange_events="ascension.events",
    )

    if missing_mandatory:
        raise MissingRequiredEnvVarError(missing_mandatory)

    return Settings(
        database=database_settings,
        storage=storage_settings,
        broker=broker_settings,
        ai=ai_settings,
        worker=worker_settings,
    )
