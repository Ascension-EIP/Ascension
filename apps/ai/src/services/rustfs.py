# @date 2026-11-01
# @file rustfs.py
# @brief RustFS (S3-compatible) storage service.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
import os
import tempfile
from collections.abc import Iterator
from contextlib import contextmanager, suppress
from pathlib import Path
from typing import Self

import boto3
from boto3.exceptions import S3TransferFailedError
from botocore.config import Config
from botocore.exceptions import BotoCoreError, ClientError

from common.models.storage import StorageModel
from common.utils.errors import PermanentError, TransientError, throw_if_none
from common.utils.logger import log

# S3 error codes meaning the object (or bucket) does not exist: retrying is useless.
_MISSING_CODES = {"404", "NoSuchKey", "NoSuchBucket", "NotFound"}


def classify_error(exc: Exception) -> Exception:
    """Map a boto3 failure to the worker error taxonomy.

    Args:
        exc: Exception raised by boto3/botocore.

    Returns:
        ``TransientError`` for network failures, timeouts and 5xx responses
        (a retry may succeed), ``PermanentError`` otherwise (missing object,
        denied access, bad request).
    """
    if isinstance(exc, ClientError):
        code = str(exc.response.get("Error", {}).get("Code", ""))
        status = exc.response.get("ResponseMetadata", {}).get("HTTPStatusCode", 0)
        if code in _MISSING_CODES or status == 404:
            return PermanentError(f"storage object or bucket not found ({code or status})")
        if status >= 500:
            return TransientError(f"storage server error ({code or status})")
        return PermanentError(f"storage request rejected ({code or status})")
    # Connection, timeout, DNS and interrupted-transfer errors.
    return TransientError(f"storage unreachable ({type(exc).__name__})")


class RustFS:
    def __init__(self):
        self.config: StorageModel | None = None
        self.client = None

    def setup_config(self) -> Self:
        self.config = StorageModel(
            endpoint=os.getenv("RUSTFS_ENDPOINT", "http://localhost:9000"),
            access_key=os.getenv("RUSTFS_ACCESS_KEY", "ascension"),
            secret_key=os.getenv("RUSTFS_SECRET_KEY", "ascension"),
            bucket=os.getenv("RUSTFS_BUCKET", "videos"),
        )
        throw_if_none(self.config)
        log.info("Storage config: %s bucket=%s", self.config.endpoint, self.config.bucket)
        return self

    def connect(self) -> Self:
        if not self.config:
            self.setup_config()

        self.client = boto3.client(
            "s3",
            endpoint_url=self.config.endpoint,
            aws_access_key_id=self.config.access_key,
            aws_secret_access_key=self.config.secret_key,
            region_name=self.config.region,
            config=Config(
                signature_version="s3v4",
                s3={"addressing_style": "path"},
                connect_timeout=10,
                read_timeout=60,
                # Retries belong to the job loop (3 attempts with backoff), not to boto.
                retries={"max_attempts": 1},
            ),
        )
        # The worker never creates the bucket: it must already exist.
        try:
            self.client.head_bucket(Bucket=self.config.bucket)
        except (ClientError, BotoCoreError) as exc:
            raise classify_error(exc) from exc
        log.info("Connected to RustFS at %s", self.config.endpoint)
        return self

    @contextmanager
    def download_temp(self, object_key: str) -> Iterator[Path]:
        """Download an object to a temporary file, deleted on exit.

        The file is removed even if the caller's block raises, so large videos
        never accumulate on disk.

        Args:
            object_key: Key of the object inside the configured bucket.

        Yields:
            Path of the temporary file (keeps the key's extension).

        Raises:
            PermanentError: The object does not exist or access is rejected.
            TransientError: Network failure, timeout or 5xx from the server.
        """
        throw_if_none(self.config)
        fd, name = tempfile.mkstemp(suffix=Path(object_key).suffix)
        os.close(fd)
        path = Path(name)
        try:
            try:
                self.client.download_file(self.config.bucket, object_key, name)
            except (ClientError, BotoCoreError, S3TransferFailedError) as exc:
                raise classify_error(exc) from exc
            yield path
        finally:
            with suppress(FileNotFoundError):
                path.unlink()
