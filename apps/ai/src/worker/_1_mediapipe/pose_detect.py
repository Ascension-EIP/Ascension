# @date 2026-11-01
# @file pose_detect.py
# @brief File description.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""Chain of the pose steps: skeleton, filter, metrics, movements. No broker, database or storage."""

from collections.abc import Callable

from shared.models import AnalysisResult
from worker._1_mediapipe.pose_filter import filter_frames
from worker._1_mediapipe.pose_metrics import compute_metrics
from worker._1_mediapipe.pose_movements import detect_movements
from worker._1_mediapipe.pose_skeleton import PoseSkeleton


def detect_pose(
    video_path: str,
    render_path: str | None = None,
    on_progress: Callable[[int], None] | None = None,
) -> AnalysisResult:
    """Run the full pose analysis of a video and return the validated result.

    Raises:
        PermanentError: The video cannot be read.
    """
    raw = PoseSkeleton().process(video_path, render_path, on_progress).result
    return AnalysisResult.model_validate(detect_movements(compute_metrics(filter_frames(raw))))
