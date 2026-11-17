# @date 2026-11-17
# @file test_colors.py
# @brief File description.
# @project Ascension
# @author Livoooo <zarigu92@gmail.com>
# @copyright (c) 2026 Ascension
# @status done
"""Tests for hold colour naming (step B3)."""

from pathlib import Path

import cv2
import numpy as np

from holds.colors import Palette, draw, image_colors

PALETTE = Palette.load(Path(__file__).resolve().parents[1] / "configs" / "colors.yaml")
WALL_BGR = (150, 150, 150)  # neutral grey wall: no colour cast


def reference_bgr(name: str) -> tuple[int, int, int]:
    """BGR colour of a uniform hold matching a palette reference on a grey wall."""
    lab = PALETTE.references[PALETTE.names.index(name)].astype(np.float32)
    bgr = cv2.cvtColor(lab.reshape(1, 1, 3), cv2.COLOR_LAB2BGR)[0, 0]
    return tuple(int(v) for v in (np.clip(bgr, 0, 1) * 255).round())


def square(x: int, y: int, size: int = 60) -> np.ndarray:
    return np.array(
        [[x, y], [x + size, y], [x + size, y + size], [x, y + size]], dtype=np.float64
    )


def wall_with_holds(holds: list[tuple[np.ndarray, tuple[int, int, int]]]) -> np.ndarray:
    image = np.full((300, 400, 3), WALL_BGR, dtype=np.uint8)
    for polygon, bgr in holds:
        cv2.fillPoly(image, [polygon.astype(np.int32)], bgr)
    return image


def test_palette_names_reference_colours_exactly():
    for name, reference in zip(PALETTE.names, PALETTE.references):
        assert PALETTE.name(reference) == (name, 0.0)


def test_every_reference_colour_is_recovered_from_an_image():
    names = PALETTE.names
    polygons = [
        square(10 + 70 * (i % 5), 10 + 70 * (i // 5), 50) for i in range(len(names))
    ]
    image = wall_with_holds([(p, reference_bgr(n)) for p, n in zip(polygons, names)])
    assert [c.name for c in image_colors(image, polygons, PALETTE)] == names


def test_chalk_does_not_wash_out_colour():
    polygon = square(100, 100, 80)
    image = wall_with_holds([(polygon, reference_bgr("blue"))])
    image[110:150, 110:170] = (235, 235, 235)  # chalk covering a large part of the hold
    (color,) = image_colors(image, [polygon], PALETTE)
    assert color.name == "blue"


def test_photo_colour_cast_is_removed():
    names = ["blue", "red", "green"]
    polygons = [square(20 + 120 * i, 20) for i in range(len(names))]
    image = wall_with_holds([(p, reference_bgr(n)) for p, n in zip(polygons, names)])
    warm = image.astype(np.int16) + np.array(
        [-20, 0, 20]
    )  # warm light on the whole photo
    warm = np.clip(warm, 0, 255).astype(np.uint8)
    assert [c.name for c in image_colors(warm, polygons, PALETTE)] == names


def test_tiny_masks_are_skipped_and_drawing_keeps_shape():
    polygons = [square(20, 20), square(200, 200, 3)]
    image = wall_with_holds([(polygons[0], reference_bgr("blue"))])
    colors = image_colors(image, polygons, PALETTE)
    assert colors[0] is not None and colors[1] is None
    assert colors[0].rgb[2] > colors[0].rgb[0]  # displayed colour is blue-ish
    assert draw(image, polygons, colors).shape == image.shape
