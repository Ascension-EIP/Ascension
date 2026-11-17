# @date 2026-09-05
# @file test_geometry.py
# @brief Unit tests for geometry and angle calculations.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""Unit tests for geometry helpers."""

import pytest

from src.common.geometry import (
    angle_between_vectors,
    compute_joint_angle,
    magnitude,
    normalize,
    vec3,
)


def test_vec3_dict():
    """Test 3D vector calculation between two point dicts."""
    p1 = {"x": 1.0, "y": 2.0, "z": 3.0}
    p2 = {"x": 4.0, "y": 6.0, "z": 3.0}
    v = vec3(p1, p2)
    assert v == [3.0, 4.0, 0.0]


def test_vec3_list():
    """Test 3D vector calculation between two point lists."""
    v = vec3([1.0, 2.0, 0.0], [4.0, 6.0, 0.0])
    assert v == [3.0, 4.0, 0.0]


def test_magnitude_and_normalize():
    """Test vector norm and normalization."""
    v = [3.0, 4.0, 0.0]
    assert magnitude(v) == 5.0

    unit = normalize(v)
    assert pytest.approx(magnitude(unit), 1e-6) == 1.0
    assert pytest.approx(unit[0], 1e-6) == 0.6
    assert pytest.approx(unit[1], 1e-6) == 0.8


def test_angle_between_perpendicular_vectors():
    """Test 90-degree angle calculation."""
    v1 = [1.0, 0.0, 0.0]
    v2 = [0.0, 1.0, 0.0]
    deg = angle_between_vectors(v1, v2)
    assert pytest.approx(deg, 1e-2) == 90.0


def test_compute_joint_angle():
    """Test joint angle formed by three points (e.g. elbow)."""
    # Shoulder at (0, 1), Elbow at (0, 0), Wrist at (1, 0) -> 90 degrees
    shoulder = {"x": 0.0, "y": 1.0, "z": 0.0}
    elbow = {"x": 0.0, "y": 0.0, "z": 0.0}
    wrist = {"x": 1.0, "y": 0.0, "z": 0.0}

    angle = compute_joint_angle(shoulder, elbow, wrist)
    assert pytest.approx(angle, 1e-2) == 90.0
