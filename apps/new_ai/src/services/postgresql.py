# @date 2026-09-10
# @file postgresql.py
# @brief File description.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
import os
from typing import Self

import psycopg
from psycopg import Connection

from common.models.database import DatabaseModel
from common.utils.errors import throw_if_none


class PostgreSQL:
    def __init__(self):
        self.config: DatabaseModel | None = None
        self.connection: Connection | None = None

    def setup_config(self) -> Self:
        self.config = DatabaseModel(
            url=os.getenv("POSTGRES_DB_URL"),
            host=os.getenv("POSTGRES_HOST", "localhost"),
            port=int(os.getenv("POSTGRES_PORT", "5432")),
            user=os.getenv("POSTGRES_USER") or "ascension",
            password=os.getenv("POSTGRES_PASSWORD") or "ascension",
            name=os.getenv("POSTGRES_DB") or "ascension",
        )
        throw_if_none(self.config)

    def connect(self) -> Self:
        if not self.config:
            self.setup_config()

        url = self.config.url or (
            f"postgresql://{self.config.user}:{self.config.password}"
            f"@{self.config.host}:{self.config.port}/{self.config.name}"
        )
        self.connection = psycopg.connect(url)
