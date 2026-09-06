# @date 2026-09-07
# @file __init__.py
# @brief 3D Pose analysis pipeline exports.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""3D Pose Analysis pipeline using SAM 3D Body."""

from src.pipelines.pose_analysis_3d.pipeline import PoseAnalysis3DPipeline
from src.pipelines.pose_analysis_3d.renderer import render_annotated_video

__all__ = ["PoseAnalysis3DPipeline", "render_annotated_video"]
