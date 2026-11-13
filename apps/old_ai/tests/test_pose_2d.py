# @date 2026-09-05
# @file test_pose_2d.py
# @brief Unit tests for 2D pose analysis pipeline and 2D advice generator.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""Unit tests for 2D pose analysis and 2D advice generation."""

from unittest.mock import MagicMock, patch

from src.pipelines.pose_analysis_2d.advice import Advice2DGenerator, summarize_for_ai
from src.pipelines.pose_analysis_2d.pipeline import PoseAnalysis2DPipeline


def test_summarize_for_ai_2d():
    """Test data reduction for 2D MediaPipe data."""
    raw_data = {
        "frames": [
            {
                "frame": 0,
                "timestamp_ms": 0,
                "pose_detected": True,
                "landmarks": {
                    "11": {"x": 0.5, "y": 0.4, "z": 0.1, "pres": 0.99},
                    "13": {"x": 0.5, "y": 0.6, "z": 0.1, "pres": 0.99},
                },
                "angles": {"13": 95.5},
            },
            {
                "frame": 1,
                "timestamp_ms": 33,
                "pose_detected": False,
            },
        ]
    }

    summary = summarize_for_ai(raw_data, sample_rate=1)
    assert len(summary) == 1
    assert summary[0]["time"] == 0
    assert "épaule_gauche" in summary[0]["points"]
    assert summary[0]["angles"]["coude_gauche"] == 95.5


def test_advice_2d_without_api_key():
    """Test that advice returns None when no API key is set."""
    generator = Advice2DGenerator(api_key=None)
    res = generator.generate({"frames": []})
    assert res is None


@patch("google.generativeai.GenerativeModel")
def test_advice_2d_with_gemini_mock(mock_model_cls):
    """Test 2D advice generation using mocked Gemini API."""
    mock_model = MagicMock()
    mock_response = MagicMock()
    mock_response.text = "## Garde les bras tendus\n- Fléchis moins les coudes\n- À [1200ms], tu forces trop"
    mock_model.generate_content.return_value = mock_response
    mock_model_cls.return_value = mock_model

    generator = Advice2DGenerator(api_key="fake_key")
    sample_data = {
        "frames": [
            {
                "frame": 0,
                "timestamp_ms": 1200,
                "pose_detected": True,
                "landmarks": {"11": {"x": 0.5, "y": 0.5}},
                "angles": {"13": 80.0},
            }
        ]
    }

    result = generator.generate(sample_data)
    assert result is not None
    assert "Garde les bras tendus" in result


def test_pipeline_2d_instantiation():
    """Test creating 2D pipeline instance."""
    pipeline = PoseAnalysis2DPipeline(model_path="dummy.task")
    assert pipeline.name == "pose_analysis_2d"
