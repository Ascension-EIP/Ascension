# @date 2026-09-17
# @file broker.py
# @brief File description.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
from collections.abc import Callable
from dataclasses import dataclass
from enum import StrEnum

from pydantic import BaseModel


@dataclass
class Bind:
    queue: str
    routing_key: str
    callback: Callable

class BrokerModel(BaseModel):
    host: str | None = None
    port: int | None = None
    user: str | None = None
    password: str | None = None
    retry_delay: int | None = None
    max_retries: int | None = None
    exchange: str | None = None


class RoutingKey(StrEnum):
    POSE_DETECT_REQUESTED = "pose.detect.requested"
    POSE_DETECT_COMPLETED = "pose.detect.completed"
    POSE_ADVICE_REQUESTED = "pose.advice.requested"
    POSE_DETECT_STATUS = "pose.detect.status"
    POSE_ADVICE_STATUS = "pose.advice.status"
