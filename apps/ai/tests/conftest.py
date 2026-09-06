# @date 2026-09-07
# @file conftest.py
# @brief Pytest fixtures and environment configuration.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""Pytest fixtures and configuration."""

import os
from collections.abc import Generator
import pytest

from src.config.settings import (
    AISettings,
    BrokerSettings,
    DatabaseSettings,
    Settings,
    StorageSettings,
    WorkerSettings,
)


@pytest.fixture
def mock_env() -> Generator[dict[str, str], None, None]:
    """Provide a clean isolated environment dictionary for tests."""
    old_env = dict(os.environ)
    test_env = {
        "POSTGRES_DB_URL": "postgres://user:pass@localhost:5432/testdb",
        "MINIO_ENDPOINT": "http://localhost:9000",
        "MINIO_ROOT_USER": "test_minio_user",
        "MINIO_ROOT_PASSWORD": "test_minio_password",
        "RABBITMQ_HOST": "localhost",
        "RABBITMQ_DEFAULT_USER": "test_rabbit_user",
        "RABBITMQ_DEFAULT_PASS": "test_rabbit_pass",
        "GEMINI_API_KEY": "test_gemini_key",
    }
    os.environ.clear()
    os.environ.update(test_env)
    try:
        yield test_env
    finally:
        os.environ.clear()
        os.environ.update(old_env)


@pytest.fixture
def sample_settings() -> Settings:
    """Provide a valid Settings object for testing."""
    return Settings(
        database=DatabaseSettings(
            db_url="postgres://user:pass@localhost:5432/testdb",
            host="localhost",
            port=5432,
            user="user",
            password="secret_db_password",
            db="testdb",
        ),
        storage=StorageSettings(
            endpoint="http://localhost:9000",
            access_key="minio_key",
            secret_key="secret_minio_password",
            bucket="videos",
        ),
        broker=BrokerSettings(
            host="localhost",
            port=5672,
            user="rabbit_user",
            password="secret_rabbit_password",
            retry_delay=1,
            max_retries=2,
            queue_skeleton="vision.skeleton",
            exchange_events="ascension.events",
        ),
        ai=AISettings(
            active_pose_pipeline="pose_analysis_2d",
            gemini_api_key="secret_gemini_key",
            gemini_model="gemini-3.1-flash-lite",
            mediapipe_model_path="pose_landmarker.task",
            sam3d_checkpoint_path="model.ckpt",
            sam3d_mhr_path="mhr.pt",
        ),
        worker=WorkerSettings(
            log_level="INFO",
            pid_file="/tmp/test_worker.pid",
        ),
    )
