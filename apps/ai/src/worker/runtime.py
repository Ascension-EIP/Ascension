# @date 2026-11-02
# @file runtime.py
# @brief File description.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""Lazy, cached access to the shared service instances.

Nothing heavy is imported or instantiated until a getter is called, so
importing ``worker`` or the handlers has no side effect.
"""

from functools import lru_cache
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from services.llm import LLM
    from services.postgresql import PostgreSQL
    from services.rabbitmq import Broker
    from services.rustfs import RustFS
    from worker._1_mediapipe._1_pose_skeleton import PoseSkeleton


@lru_cache(maxsize=1)
def get_broker() -> "Broker":
    from services.rabbitmq import Broker

    return Broker()


@lru_cache(maxsize=1)
def get_db() -> "PostgreSQL":
    from services.postgresql import PostgreSQL

    return PostgreSQL()


@lru_cache(maxsize=1)
def get_storage() -> "RustFS":
    from services.rustfs import RustFS

    return RustFS()


@lru_cache(maxsize=1)
def get_pose_skeleton() -> "PoseSkeleton":
    from worker._1_mediapipe._1_pose_skeleton import PoseSkeleton

    return PoseSkeleton()


@lru_cache(maxsize=1)
def get_llm() -> "LLM":
    """Build the LLM client on first use; raises `ValueError` while LLM_BASE_URL or LLM_MODEL is unset."""
    from services.llm import LLM

    return LLM().setup_config().connect()
