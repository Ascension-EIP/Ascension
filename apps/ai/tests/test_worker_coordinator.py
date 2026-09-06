# @date 2026-09-07
# @file test_worker_coordinator.py
# @brief Unit tests for the worker JobCoordinator orchestration.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""Unit tests for worker JobCoordinator."""

import json
from unittest.mock import MagicMock, patch

from src.core.interfaces import BasePipeline
from src.pipelines.registry import PipelineRegistry
from src.worker.coordinator import JobCoordinator


class MockTestPipeline(BasePipeline):
    """Pipeline mock for coordinator tests."""

    @property
    def name(self) -> str:
        return "mock_test_pipeline"

    def analyze(self, video_path: str, on_progress=None, **kwargs):
        if on_progress:
            on_progress(50)
        return {"frames": [{"frame": 0, "pose_detected": True}]}


def test_coordinator_handles_successful_job(sample_settings):
    """Test full successful job lifecycle orchestration."""
    mock_storage = MagicMock()
    mock_storage.download_video.return_value = "/tmp/fake_vid.mp4"

    mock_db = MagicMock()
    mock_conn = MagicMock()
    mock_db.get_connection.return_value = mock_conn

    mock_messaging = MagicMock()

    coordinator = JobCoordinator(
        settings=sample_settings,
        storage=mock_storage,
        db_repo=mock_db,
        messaging=mock_messaging,
    )

    PipelineRegistry.register("mock_test_pipeline")(MockTestPipeline)

    payload = {
        "job_id": "job-123",
        "analysis_id": "analysis-456",
        "video_url": "s3://videos/test.mp4",
        "pipeline": "mock_test_pipeline",
    }
    body = json.dumps(payload).encode("utf-8")

    mock_channel = MagicMock()
    mock_method = MagicMock()
    mock_method.delivery_tag = 1

    with patch("os.path.exists", return_value=False):
        coordinator.handle_message(mock_channel, mock_method, None, body)

    # 1. Video was downloaded
    mock_storage.download_video.assert_called_once_with("s3://videos/test.mp4")

    # 2. Progress was updated
    mock_db.update_progress.assert_called_with(mock_conn, "analysis-456", 50)

    # 3. Results were saved
    mock_db.save_completed.assert_called_once()
    saved_analysis_id = mock_db.save_completed.call_args[1]["analysis_id"]
    assert saved_analysis_id == "analysis-456"

    # 4. Event was published
    mock_messaging.publish_event.assert_called_once()
    routing_key = mock_messaging.publish_event.call_args[0][1]
    assert routing_key == "skeleton.completed.job-123"

    # 5. Message was acknowledged
    mock_channel.basic_ack.assert_called_once_with(delivery_tag=1)


def test_coordinator_handles_failure_gracefully(sample_settings):
    """Test that job failures mark analysis failed and nack the message."""
    mock_storage = MagicMock()
    mock_storage.download_video.side_effect = RuntimeError("S3 Connection dropped")

    mock_db = MagicMock()
    mock_conn = MagicMock()
    mock_db.get_connection.return_value = mock_conn

    mock_messaging = MagicMock()

    coordinator = JobCoordinator(
        settings=sample_settings,
        storage=mock_storage,
        db_repo=mock_db,
        messaging=mock_messaging,
    )

    payload = {
        "job_id": "job-fail",
        "analysis_id": "analysis-fail",
        "video_url": "s3://videos/fail.mp4",
    }
    body = json.dumps(payload).encode("utf-8")

    mock_channel = MagicMock()
    mock_method = MagicMock()
    mock_method.delivery_tag = 2

    coordinator.handle_message(mock_channel, mock_method, None, body)

    mock_db.mark_failed.assert_called_once_with(mock_conn, "analysis-fail")
    mock_channel.basic_nack.assert_called_once_with(delivery_tag=2, requeue=False)
