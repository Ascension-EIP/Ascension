# @date 2026-09-07
# @file test_config.py
# @brief Unit tests for configuration validation, fail-fast behavior, and secret masking.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""Unit tests for configuration security and validation."""

import os
import pytest

from src.config.exceptions import InvalidEnvVarValueError, MissingRequiredEnvVarError
from src.config.security import mask_dict, mask_value
from src.config.validator import load_ai_settings, load_settings


def test_missing_mandatory_vars_raises_error(monkeypatch: pytest.MonkeyPatch):
    """Test that missing mandatory variables fail fast with MissingRequiredEnvVarError."""
    monkeypatch.setattr(os, "environ", {})

    with pytest.raises(MissingRequiredEnvVarError) as exc_info:
        load_settings(standalone=False, load_env=False)

    msg = str(exc_info.value)
    assert "CONFIGURATION ERROR" in msg
    assert "POSTGRES_USER" in msg or "POSTGRES_DB_URL" in msg
    assert "MINIO_ROOT_USER" in msg
    assert "MINIO_ROOT_PASSWORD" in msg


def test_optional_vars_use_defaults(monkeypatch: pytest.MonkeyPatch):
    """Test that optional environment variables take sensible defaults."""
    env = {
        "POSTGRES_DB_URL": "postgres://user:pass@localhost:5432/ascension",
        "MINIO_ROOT_USER": "test_user",
        "MINIO_ROOT_PASSWORD": "test_password",
        "RABBITMQ_DEFAULT_USER": "rabbit",
        "RABBITMQ_DEFAULT_PASS": "rabbit_pass",
    }
    monkeypatch.setattr(os, "environ", env)

    settings = load_settings(standalone=False, load_env=False)
    assert settings.broker.port == 5672
    assert settings.broker.host == "localhost"
    assert settings.storage.bucket == "videos"
    assert settings.ai.active_pose_pipeline == "pose_analysis_2d"
    assert settings.ai.gemini_model == "gemini-3.1-flash-lite"
    assert settings.worker.log_level == "INFO"


def test_invalid_integer_env_var_raises_error(monkeypatch: pytest.MonkeyPatch):
    """Test that non-integer values for integer variables raise InvalidEnvVarValueError."""
    env = {
        "POSTGRES_DB_URL": "postgres://user:pass@localhost:5432/ascension",
        "POSTGRES_PORT": "not_a_number",
        "MINIO_ROOT_USER": "test_user",
        "MINIO_ROOT_PASSWORD": "test_password",
        "RABBITMQ_DEFAULT_USER": "rabbit",
        "RABBITMQ_DEFAULT_PASS": "rabbit_pass",
    }
    monkeypatch.setattr(os, "environ", env)

    with pytest.raises(InvalidEnvVarValueError) as exc_info:
        load_settings(standalone=False, load_env=False)
    assert "POSTGRES_PORT" in str(exc_info.value)


def test_mask_value():
    """Test secret masking utility."""
    assert mask_value("") == "<empty>"
    assert mask_value(None) == "<empty>"
    assert mask_value("123") == "***"
    assert mask_value("super_secret_password") == "su***rd"


def test_mask_dict_recursively():
    """Test recursive masking of sensitive dictionary keys."""
    data = {
        "host": "localhost",
        "user_password": "my_db_password",
        "gemini_api_key": "AIzaSyD-123456789",
        "nested": {
            "secret_token": "bearer-xyz",
            "public_id": "item-123",
        },
    }
    masked = mask_dict(data)
    assert masked["host"] == "localhost"
    assert masked["user_password"] == "my***rd"
    assert masked["gemini_api_key"] == "AI***89"
    assert masked["nested"]["secret_token"] == "be***yz"
    assert masked["nested"]["public_id"] == "item-123"


def test_standalone_ai_settings_does_not_require_db(monkeypatch: pytest.MonkeyPatch):
    """Test that standalone AI settings can be loaded without DB or broker variables."""
    monkeypatch.setattr(os, "environ", {"GEMINI_API_KEY": "test_key"})
    ai_settings = load_ai_settings(load_env=False)
    assert ai_settings.gemini_api_key == "test_key"
    assert ai_settings.active_pose_pipeline == "pose_analysis_2d"
