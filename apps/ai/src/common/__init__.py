# @date 2026-09-05
# @file __init__.py
# @brief Common math and video utilities.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""Common shared utilities."""

from src.common.geometry import (
    angle_between_vectors,
    compute_joint_angle,
    magnitude,
    normalize,
    vec3,
)
from src.common.video import (
    VideoMetadata,
    get_video_metadata,
    open_video,
    read_frames,
    resize_frame_if_needed,
)

__all__ = [
    "VideoMetadata",
    "angle_between_vectors",
    "compute_joint_angle",
    "get_video_metadata",
    "magnitude",
    "normalize",
    "open_video",
    "read_frames",
    "resize_frame_if_needed",
    "vec3",
]
