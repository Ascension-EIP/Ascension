# @date 2026-09-07
# @file storage.py
# @brief MinIO and S3 object storage adapter.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""MinIO and S3 storage adapter."""

import logging
import os
import tempfile
from urllib.parse import urlparse

import boto3
from botocore.exceptions import BotoCoreError, ClientError

from src.config.settings import StorageSettings
from src.core.exceptions import StorageError

logger = logging.getLogger("ai-worker.storage")


class StorageService:
    """Service for interacting with MinIO/S3 object storage."""

    def __init__(self, settings: StorageSettings):
        self.settings = settings
        self._client = boto3.client(
            "s3",
            endpoint_url=settings.endpoint,
            aws_access_key_id=settings.access_key,
            aws_secret_access_key=settings.secret_key,
            region_name=settings.region,
        )

    @staticmethod
    def parse_s3_url(url: str) -> tuple[str, str]:
        """Parse 's3://bucket/key' into (bucket, key)."""
        parsed = urlparse(url)
        if parsed.scheme != "s3":
            raise StorageError(f"Expected s3:// URL scheme, got: {url!r}")
        bucket = parsed.netloc
        key = parsed.path.lstrip("/")
        if not bucket or not key:
            raise StorageError(f"Invalid S3 URL format: {url!r}")
        return bucket, key

    def download_video(self, video_url: str) -> str:
        """Download video from MinIO/S3 to a temporary file and return its path."""
        bucket, key = self.parse_s3_url(video_url)
        suffix = os.path.splitext(key)[1] or ".mp4"
        tmp = tempfile.NamedTemporaryFile(delete=False, suffix=suffix)
        try:
            logger.info("Downloading s3://%s/%s → %s", bucket, key, tmp.name)
            self._client.download_fileobj(bucket, key, tmp)
            tmp.close()
            return tmp.name
        except (BotoCoreError, ClientError, Exception) as e:
            tmp.close()
            if os.path.exists(tmp.name):
                os.unlink(tmp.name)
            raise StorageError(f"Failed to download video from {video_url}: {e}") from e
