# @date 2026-09-07
# @file test_registry.py
# @brief Unit tests for the AI PipelineRegistry.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""Unit tests for pipeline registry."""

import pytest

from src.core.exceptions import PipelineNotFoundError
from src.core.interfaces import BasePipeline
from src.pipelines.registry import PipelineRegistry


class DummyPipeline(BasePipeline):
    """Mock pipeline for registry testing."""

    @property
    def name(self) -> str:
        return "dummy"

    def analyze(self, video_path: str, on_progress=None, **kwargs):
        return {"frames": []}


def test_registry_register_and_get():
    """Test registering and retrieving a pipeline."""
    PipelineRegistry.register("dummy_test")(DummyPipeline)
    instance = PipelineRegistry.get("dummy_test")
    assert isinstance(instance, DummyPipeline)
    assert instance.name == "dummy"


def test_registry_unknown_pipeline_raises():
    """Test that requesting an unregistered pipeline raises PipelineNotFoundError."""
    with pytest.raises(PipelineNotFoundError) as exc_info:
        PipelineRegistry.get("non_existent_pipeline_xyz")
    assert "non_existent_pipeline_xyz" in str(exc_info.value)


def test_builtin_pipelines_registered():
    """Test that pose_analysis_2d and pose_analysis_3d are registered by default."""
    import src.pipelines  # noqa: F401 (Trigger registrations)
    pipelines = PipelineRegistry.list_pipelines()
    assert "pose_analysis_2d" in pipelines
    assert "pose_analysis_3d" in pipelines
