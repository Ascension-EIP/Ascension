# @date 2026-11-12
# @file test_rustfs.py
# @brief Unit tests for the RustFS service (mocked boto3 client).
# @project Ascension
# @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>, Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
from pathlib import Path
from unittest.mock import MagicMock

import pytest
from botocore.exceptions import (
    ClientError,
    ConnectTimeoutError,
    EndpointConnectionError,
)

from common.utils.errors import PermanentError, TransientError
from services.rustfs import RustFS


def client_error(code: str, status: int) -> ClientError:
    return ClientError({"Error": {"Code": code}, "ResponseMetadata": {"HTTPStatusCode": status}}, "GetObject")


def make_storage(download=None) -> RustFS:
    storage = RustFS().setup_config()
    storage.client = MagicMock()
    if download:
        storage.client.download_file.side_effect = download
    return storage


def write_file(bucket, key, path):
    Path(path).write_bytes(b"video")


def test_download_temp_deletes_file_after_block():
    storage = make_storage(write_file)
    with storage.download_temp("a/b/video.mp4") as path:
        assert path.suffix == ".mp4"
        assert path.read_bytes() == b"video"
    assert not path.exists()
    storage.client.download_file.assert_called_once_with("videos", "a/b/video.mp4", str(path))


def test_download_temp_deletes_file_on_exception():
    storage = make_storage(write_file)
    seen = []
    with pytest.raises(RuntimeError), storage.download_temp("v.mp4") as path:
        seen.append(path)
        raise RuntimeError("boom")
    assert not seen[0].exists()


@pytest.mark.parametrize("code", ["404", "NoSuchKey"])
def test_missing_object_is_permanent(code):
    storage = make_storage(client_error(code, 404))
    with pytest.raises(PermanentError), storage.download_temp("missing.mp4"):
        pass


def test_access_denied_is_permanent():
    storage = make_storage(client_error("AccessDenied", 403))
    with pytest.raises(PermanentError), storage.download_temp("v.mp4"):
        pass


@pytest.mark.parametrize(
    "error",
    [
        client_error("InternalError", 500),
        client_error("ServiceUnavailable", 503),
        EndpointConnectionError(endpoint_url="http://x"),
        ConnectTimeoutError(endpoint_url="http://x"),
    ],
)
def test_network_and_5xx_are_transient(error):
    storage = make_storage(error)
    with pytest.raises(TransientError), storage.download_temp("v.mp4"):
        pass


def test_failed_download_leaves_no_file():
    storage = make_storage(client_error("404", 404))
    created = []
    real = Path.unlink

    def spy(self, *a, **k):
        created.append(self)
        return real(self, *a, **k)

    with pytest.MonkeyPatch.context() as mp:
        mp.setattr(Path, "unlink", spy)
        with pytest.raises(PermanentError), storage.download_temp("v.mp4"):
            pass
    assert created
    assert not created[0].exists()


def test_region_defaults_to_us_east_1(monkeypatch):
    monkeypatch.delenv("STORAGE_REGION", raising=False)
    monkeypatch.delenv("RUSTFS_REGION", raising=False)
    assert RustFS().setup_config().config.region == "us-east-1"


def test_region_is_read_from_env(monkeypatch):
    # OVHcloud Object Storage rejects signatures made for another region.
    monkeypatch.delenv("STORAGE_REGION", raising=False)
    monkeypatch.setenv("RUSTFS_REGION", "gra")
    assert RustFS().setup_config().config.region == "gra"


def test_storage_env_vars_take_precedence_over_rustfs(monkeypatch):
    monkeypatch.setenv("STORAGE_ENDPOINT", "http://storage.test:9000")
    monkeypatch.setenv("STORAGE_ID", "storage-id")
    monkeypatch.setenv("STORAGE_SECRET", "storage-secret")
    monkeypatch.setenv("STORAGE_BUCKET", "storage-bucket")
    monkeypatch.setenv("STORAGE_REGION", "gra")
    monkeypatch.setenv("RUSTFS_ENDPOINT", "http://rustfs.test:9000")
    monkeypatch.setenv("RUSTFS_ACCESS_KEY", "rustfs-id")
    monkeypatch.setenv("RUSTFS_SECRET_KEY", "rustfs-secret")
    monkeypatch.setenv("RUSTFS_BUCKET", "rustfs-bucket")
    monkeypatch.setenv("RUSTFS_REGION", "us-east-1")
    config = RustFS().setup_config().config
    assert config.endpoint == "http://storage.test:9000"
    assert config.access_key == "storage-id"
    assert config.secret_key == "storage-secret"
    assert config.bucket == "storage-bucket"
    assert config.region == "gra"
