# @date 2026-09-10
# @file database.py
# @brief File description.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
from pydantic import BaseModel


class DatabaseModel(BaseModel):
    url: str | None = None
    host: str | None = None
    port: int | None = None
    user: str | None = None
    password: str | None = None
    name: str | None = None
