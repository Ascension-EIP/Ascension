# @date 2026-09-07
# @file geometry.py
# @brief Geometry and vector math helpers for 2D and 3D pose analysis.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""Geometry and vector mathematics helpers."""

import numpy as np


def vec3(
    a: dict[str, float] | list[float], b: dict[str, float] | list[float]
) -> list[float]:
    """Compute vector from point a to point b (3D)."""
    if isinstance(a, dict) and isinstance(b, dict):
        return [
            b["x"] - a["x"],
            b["y"] - a["y"],
            b.get("z", 0.0) - a.get("z", 0.0),
        ]
    return [b[0] - a[0], b[1] - a[1], b[2] - a[2]]


def magnitude(v: list[float] | np.ndarray) -> float:
    """Compute Euclidean norm (magnitude) of a vector."""
    return float(np.linalg.norm(v))


def normalize(v: list[float] | np.ndarray) -> list[float] | np.ndarray:
    """Normalize a vector to unit length."""
    m = magnitude(v)
    if m > 0:
        if isinstance(v, np.ndarray):
            return v / m
        return [x / m for x in v]
    return v


def angle_between_vectors(
    v1: list[float] | np.ndarray, v2: list[float] | np.ndarray
) -> float:
    """Compute the angle in degrees between two vectors."""
    n1 = np.linalg.norm(v1)
    n2 = np.linalg.norm(v2)
    if n1 == 0 or n2 == 0:
        return 0.0
    dot_val = np.dot(v1, v2) / (n1 * n2)
    cos_val = np.clip(dot_val, -1.0, 1.0)
    return float(np.degrees(np.arccos(cos_val)))


def compute_joint_angle(
    a: dict[str, float] | list[float],
    joint: dict[str, float] | list[float],
    b: dict[str, float] | list[float],
) -> float:
    """Compute angle in degrees formed at `joint` between `a` and `b`.

    Vectors are (joint -> a) and (joint -> b).
    """
    v1 = vec3(joint, a)
    v2 = vec3(joint, b)
    return round(angle_between_vectors(v1, v2), 2)
