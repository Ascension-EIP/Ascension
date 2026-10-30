# @date 2026-10-25
# @file storage.py
# @brief File description.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
from pydantic import BaseModel


class StorageModel(BaseModel):
    endpoint: str | None = None
    access_key: str | None = None
    secret_key: str | None = None
    bucket: str | None = None
    region: str = "us-east-1"
