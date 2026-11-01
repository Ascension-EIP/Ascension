# @date 2026-11-01
# @file pose_geometry.py
# @brief File description.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""Pixel-space geometry shared by the pose steps (no MediaPipe import)."""

import numpy as np

#: Angle at vertex ``B`` formed by the landmarks ``A-B-C`` (lowercase MediaPipe names).
#: Names match the `body_zone` enum of the database schema.
JOINTS: dict[str, tuple[str, str, str]] = {
    "left_shoulder": ("left_elbow", "left_shoulder", "left_hip"),
    "right_shoulder": ("right_elbow", "right_shoulder", "right_hip"),
    "left_elbow": ("left_shoulder", "left_elbow", "left_wrist"),
    "right_elbow": ("right_shoulder", "right_elbow", "right_wrist"),
    "left_hip": ("left_shoulder", "left_hip", "left_knee"),
    "right_hip": ("right_shoulder", "right_hip", "right_knee"),
    "left_knee": ("left_hip", "left_knee", "left_ankle"),
    "right_knee": ("right_hip", "right_knee", "right_ankle"),
    "left_ankle": ("left_knee", "left_ankle", "left_foot_index"),
    "right_ankle": ("right_knee", "right_ankle", "right_foot_index"),
}

#: Decimal places kept for angles (degrees).
ANGLE_PRECISION = 1


def to_px(lm: dict, width: int, height: int) -> np.ndarray:
    """Convert a normalized landmark to pixels (x, y only).

    ``z`` is deliberately dropped. Measured on ``example-2.mp4`` (camera-facing
    z scaled by width): 3D angles differ from 2D by 5 to 50 degrees on average
    depending on the joint, and frame-to-frame jitter is not lower with z
    (higher on 5 of 10 joints, e.g. right_elbow 8.3 vs 3.6 deg). Nothing
    justifies the noise, and every step (angles, speeds, extension) must use
    the same space.
    """
    return np.array([lm["x"] * width, lm["y"] * height])


def angle(a: np.ndarray, b: np.ndarray, c: np.ndarray) -> float | None:
    """Angle in degrees at ``b``, or ``None`` if a segment has zero length."""
    ba, bc = a - b, c - b
    norm = np.linalg.norm(ba) * np.linalg.norm(bc)
    if norm == 0:
        return None
    return float(np.degrees(np.arccos(np.clip(ba @ bc / norm, -1.0, 1.0))))


def frame_angles(landmarks: dict[str, dict], width: int, height: int) -> dict[str, float]:
    """Joint angles computable from the landmarks present; others are omitted."""
    out: dict[str, float] = {}
    for name, (a, b, c) in JOINTS.items():
        if a in landmarks and b in landmarks and c in landmarks:
            value = angle(*(to_px(landmarks[n], width, height) for n in (a, b, c)))
            if value is not None:
                out[name] = round(value, ANGLE_PRECISION)
    return out
