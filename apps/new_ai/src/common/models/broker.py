# @date 2026-09-17
# @file broker.py
# @brief File description.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
from dataclasses import dataclass

from pydantic import BaseModel


@dataclass
class Bind:
    queue: str
    routing_key: str


BROKER_BINDINGS: list[Bind] = [
    Bind(queue="poses.detect", routing_key="pose.detect.requested"),
    Bind(queue="poses.analyze", routing_key="pose.detect.completed"),
]


class BrokerModel(BaseModel):
    host: str | None = None
    port: int | None = None
    user: str | None = None
    password: str | None = None
    retry_delay: int | None = None
    max_retries: int | None = None
    exchange: str | None = None
