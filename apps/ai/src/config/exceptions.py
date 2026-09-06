# @date 2026-09-07
# @file exceptions.py
# @brief Configuration and environment validation exceptions.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""Configuration and security exceptions."""


class ConfigurationError(Exception):
    """Base exception for all configuration and security issues."""


class MissingRequiredEnvVarError(ConfigurationError):
    """Raised when a mandatory environment variable is missing."""

    def __init__(self, missing_vars: list[str]):
        self.missing_vars = missing_vars
        msg = (
            "\n" + "=" * 70 + "\n"
            "CONFIGURATION ERROR: Missing mandatory environment variable(s):\n"
            + "\n".join(f"  - {v}" for v in missing_vars)
            + "\nExecution stopped. Please check your .env file or environment."
            "\n" + "=" * 70
        )
        super().__init__(msg)


class InvalidEnvVarValueError(ConfigurationError):
    """Raised when an environment variable has an invalid value or format."""
