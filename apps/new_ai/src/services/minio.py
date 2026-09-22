# @date 2026-09-11
# @file minio.py
# @brief File description.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
import os
from typing import Self

from minio import Minio

from common.models.storage import StorageModel
from common.utils.errors import throw_if_none


class MinIO:
    def __init__(self):
        self.config: StorageModel | None = None
        self.client: Minio | None = None

    def setup_config(self) -> Self:
        endpoint = os.getenv("MINIO_ENDPOINT")
        if not endpoint:
            minio_host = os.getenv("MINIO_HOST", "localhost")
            minio_port = os.getenv("MINIO_PORT", "9000")
            endpoint = f"http://{minio_host}:{minio_port}"

        access_key = (
            os.getenv("MINIO_ROOT_USER")
            or os.getenv("MINIO_ID")
            or os.getenv("AWS_ACCESS_KEY_ID")
        )
        secret_key = (
            os.getenv("MINIO_ROOT_PASSWORD")
            or os.getenv("MINIO_SECRET")
            or os.getenv("AWS_SECRET_ACCESS_KEY")
        )

        self.config = StorageModel(
            endpoint=endpoint,
            access_key=access_key or "ascension",
            secret_key=secret_key or "ascension",
            bucket=os.getenv("MINIO_BUCKET", "videos"),
        )
        throw_if_none(self.config)

    def connect(self) -> Self:
        if not self.config:
            self.setup_config()

        endpoint = self.config.endpoint or "http://localhost:9000"
        secure = endpoint.startswith("https://")
        host = endpoint.removeprefix("https://").removeprefix("http://")

        self.client = Minio(
            host,
            access_key=self.config.access_key,
            secret_key=self.config.secret_key,
            secure=secure,
            region=self.config.region,
        )

        bucket = self.config.bucket
        if bucket and not self.client.bucket_exists(bucket):
            self.client.make_bucket(bucket)
