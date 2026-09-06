# @date 2026-09-07
# @file __init__.py
# @brief 2D Pose analysis pipeline exports.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""2D Pose Analysis pipeline using MediaPipe."""

from src.pipelines.pose_analysis_2d.pipeline import PoseAnalysis2DPipeline
from src.pipelines.pose_analysis_2d.renderer import render_annotated_video

__all__ = ["PoseAnalysis2DPipeline", "render_annotated_video"]
