# @date 2026-09-05
# @file video.py
# @brief OpenCV video handling and processing utilities.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""OpenCV video handling utilities."""

import os
from collections.abc import Generator
from dataclasses import dataclass

import cv2
import numpy as np

from src.core.exceptions import VideoProcessingError


@dataclass(frozen=True)
class VideoMetadata:
    """Metadata extracted from a video file."""

    fps: float
    frame_count: int
    width: int
    height: int
    duration_s: float


def open_video(video_path: str) -> cv2.VideoCapture:
    """Open a video file safely, raising VideoProcessingError on failure."""
    if not os.path.isfile(video_path):
        raise FileNotFoundError(f"Video file not found: {video_path}")

    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        raise VideoProcessingError(
            f"OpenCV could not open video: {video_path}. Verify codec / ffmpeg."
        )
    return cap


def get_video_metadata(cap: cv2.VideoCapture) -> VideoMetadata:
    """Extract metadata from an open VideoCapture."""
    fps = cap.get(cv2.CAP_PROP_FPS)
    if fps <= 0:
        fps = 30.0
    frame_count = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    duration_s = (frame_count / fps) if fps > 0 else 0.0

    return VideoMetadata(
        fps=fps,
        frame_count=frame_count,
        width=width,
        height=height,
        duration_s=duration_s,
    )


def resize_frame_if_needed(
    frame: np.ndarray, max_width: int
) -> tuple[np.ndarray, float]:
    """Resize frame if wider than max_width, maintaining aspect ratio.

    Returns (resized_frame, scale_factor).
    """
    h, w = frame.shape[:2]
    if w > max_width:
        scale = max_width / w
        new_h = int(h * scale)
        resized = cv2.resize(frame, (max_width, new_h), interpolation=cv2.INTER_AREA)
        return resized, scale
    return frame, 1.0


def read_frames(
    cap: cv2.VideoCapture,
    frame_step: int = 1,
) -> Generator[tuple[int, int, np.ndarray], None, None]:
    """Yield (frame_index, timestamp_ms, frame_bgr) for sampled frames."""
    fps = cap.get(cv2.CAP_PROP_FPS) or 30.0
    i = 0
    while True:
        ret, frame = cap.read()
        if not ret:
            break
        if i % frame_step == 0:
            timestamp_ms = int((i / fps) * 1000)
            yield i, timestamp_ms, frame
        i += 1
