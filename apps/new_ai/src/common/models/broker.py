# @date 2026-09-10
# @file broker.py
# @brief File description.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
from pydantic import BaseModel


class BrokerModel(BaseModel):
    host: str | None = None
    port: int | None = None
    user: str | None = None
    password: str | None = None
    retry_delay: int | None = None
    max_retries: int | None = None
    queue: str | None = None
    exchange: str | None = None
