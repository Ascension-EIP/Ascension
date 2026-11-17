# @date 2026-09-05
# @file test_pose_3d.py
# @brief Unit tests for 3D pose analysis pipeline and 3D advice generator.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""Unit tests for 3D pose analysis and 3D advice generation."""

from unittest.mock import MagicMock, patch

from src.pipelines.pose_analysis_3d.advice import Advice3DGenerator, summarize_3d_for_ai
from src.pipelines.pose_analysis_3d.pipeline import PoseAnalysis3DPipeline


def test_summarize_3d_for_ai():
    """Test 3D data reduction with depth and spatial coordinates."""
    raw_data = {
        "frames": [
            {
                "frame": 0,
                "timestamp_ms": 100,
                "people": [
                    {
                        "pred_cam_t": [0.1, 0.2, 2.5],
                        "landmarks": {
                            "left_hip": {"x": 0.2, "y": 0.8, "z": 2.45},
                        },
                        "angles": {"left_knee": 110.0},
                    }
                ],
            }
        ]
    }

    summary = summarize_3d_for_ai(raw_data, sample_rate=1)
    assert len(summary) == 1
    assert summary[0]["camera_translation_m"] == [0.1, 0.2, 2.5]
    assert summary[0]["landmarks_3d_m"]["left_hip"]["z_depth"] == 2.45
    assert summary[0]["angles_3d_deg"]["left_knee"] == 110.0


def test_advice_3d_without_api_key():
    """Test that 3D advice returns None when no API key is set."""
    generator = Advice3DGenerator(api_key=None)
    res = generator.generate({"frames": []})
    assert res is None


@patch("google.generativeai.GenerativeModel")
def test_advice_3d_with_gemini_mock(mock_model_cls):
    """Test 3D advice generation using mocked Gemini API."""
    mock_model = MagicMock()
    mock_response = MagicMock()
    mock_response.text = "## Bassin trop éloigné\n- Rapproche ton bassin du mur\n- À [100ms], ton centre de gravité est trop en arrière"
    mock_model.generate_content.return_value = mock_response
    mock_model_cls.return_value = mock_model

    generator = Advice3DGenerator(api_key="fake_key")
    sample_data = {
        "frames": [
            {
                "frame": 0,
                "timestamp_ms": 100,
                "people": [
                    {
                        "pred_cam_t": [0.0, 0.0, 3.0],
                        "landmarks": {"left_hip": {"x": 0.0, "y": 0.0, "z": 3.2}},
                        "angles": {"left_hip": 120.0},
                    }
                ],
            }
        ]
    }

    result = generator.generate(sample_data)
    assert result is not None
    assert "Bassin trop éloigné" in result


def test_pipeline_3d_instantiation():
    """Test creating 3D pipeline instance."""
    pipeline = PoseAnalysis3DPipeline(checkpoint_path="dummy.ckpt")
    assert pipeline.name == "pose_analysis_3d"
