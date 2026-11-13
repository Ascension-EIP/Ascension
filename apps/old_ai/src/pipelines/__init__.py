# @date 2026-09-05
# @file __init__.py
# @brief Pipelines package initialization and registry setup.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""AI Pipelines package."""

from src.pipelines.base import AdviceCapability, BasePipeline
from src.pipelines.pose_analysis_2d import PoseAnalysis2DPipeline
from src.pipelines.pose_analysis_3d import PoseAnalysis3DPipeline
from src.pipelines.registry import PipelineRegistry

# Register available pipelines
PipelineRegistry.register("pose_analysis_2d")(PoseAnalysis2DPipeline)
PipelineRegistry.register("pose_analysis_3d")(PoseAnalysis3DPipeline)
# Also register alias for backward compatibility or shortcuts
PipelineRegistry.register("mediapipe")(PoseAnalysis2DPipeline)
PipelineRegistry.register("sam3d")(PoseAnalysis3DPipeline)

__all__ = [
    "AdviceCapability",
    "BasePipeline",
    "PipelineRegistry",
    "PoseAnalysis2DPipeline",
    "PoseAnalysis3DPipeline",
]
