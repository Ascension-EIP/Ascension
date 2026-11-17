# @date 2026-11-17
# @file colors.py
# @brief File description.
# @project Ascension
# @author Livoooo <zarigu92@gmail.com>
# @copyright (c) 2026 Ascension
# @status done
"""Dominant colour of each detected hold (pipeline step B3).

Hold pixels are summarised in CIELAB space so that lightness and colour are
separated:

- the mask is eroded so that wall pixels on the hold border are ignored;
- chalk desaturates holds, so the colour (a*, b*) is the median of the 10 %
  most saturated pixels only;
- the lightness is the 25th percentile, chalk being lighter than the hold;
- the colour cast of the photo is removed using the wall around the holds.

The descriptor is then named after the closest reference colour of
`configs/colors.yaml`.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import cv2
import numpy as np
import yaml

MIN_PIXELS = 20
EROSION_RATIO = 0.1  # erosion radius, relative to the square root of the mask area
KEEP_AFTER_EROSION = (
    0.3  # fall back to the raw mask when erosion removes more than this
)
SATURATED_PERCENTILE = 90
LIGHTNESS_PERCENTILE = 25


@dataclass
class HoldColor:
    """Colour of one hold."""

    name: str
    distance: float  # distance to the reference colour, lower is more reliable
    descriptor: tuple[float, float, float]  # (L, a, b) after wall correction
    rgb: tuple[int, int, int]  # representative colour, for display


@dataclass
class Palette:
    """Reference colours used to name hold descriptors."""

    names: list[str]
    references: np.ndarray  # (n, 3) descriptors
    lightness_weight: float

    @classmethod
    def load(cls, path: Path) -> Palette:
        """Load the palette from a `colors.yaml` file."""
        data = yaml.safe_load(path.read_text(encoding="utf-8"))
        names = list(data["colors"])
        return cls(
            names=names,
            references=np.array([data["colors"][n] for n in names], dtype=np.float64),
            lightness_weight=float(data["lightness_weight"]),
        )

    def name(self, descriptor: np.ndarray) -> tuple[str, float]:
        """Return the closest reference colour and its distance."""
        weights = np.array([self.lightness_weight, 1.0, 1.0])
        distances = np.linalg.norm((self.references - descriptor) * weights, axis=1)
        best = int(np.argmin(distances))
        return self.names[best], float(distances[best])


def to_lab(image_bgr: np.ndarray) -> np.ndarray:
    """Convert an 8-bit BGR image to float CIELAB (L in 0-100, a/b around 0)."""
    return cv2.cvtColor(image_bgr.astype(np.float32) / 255, cv2.COLOR_BGR2LAB)


def wall_cast(lab: np.ndarray, holds_mask: np.ndarray) -> np.ndarray:
    """Median (a, b) of the pixels outside every hold, i.e. the photo colour cast."""
    background = lab[~holds_mask]
    if len(background) == 0:
        return np.zeros(2)
    return np.median(background[:, 1:], axis=0)


def hold_pixels(lab: np.ndarray, mask: np.ndarray) -> np.ndarray:
    """Lab pixels of a hold, without its border."""
    mask = mask.astype(np.uint8)
    radius = max(1, int(EROSION_RATIO * np.sqrt(mask.sum())))
    kernel = cv2.getStructuringElement(
        cv2.MORPH_ELLIPSE, (2 * radius + 1, 2 * radius + 1)
    )
    eroded = cv2.erode(mask, kernel)
    keep = eroded if eroded.sum() > KEEP_AFTER_EROSION * mask.sum() else mask
    return lab[keep.astype(bool)]


def hold_color(
    lab: np.ndarray, mask: np.ndarray, cast: np.ndarray, palette: Palette
) -> HoldColor | None:
    """Describe and name the colour of the hold covered by `mask` (None if too small)."""
    pixels = hold_pixels(lab, mask)
    if len(pixels) < MIN_PIXELS:
        return None
    chroma = np.hypot(pixels[:, 1], pixels[:, 2])
    saturated = pixels[chroma >= np.percentile(chroma, SATURATED_PERCENTILE)]
    a, b = np.median(saturated[:, 1:], axis=0)
    lightness = float(np.percentile(pixels[:, 0], LIGHTNESS_PERCENTILE))
    descriptor = np.array([lightness, a - cast[0], b - cast[1]])
    name, distance = palette.name(descriptor)

    display = np.array([[[np.median(saturated[:, 0]), a, b]]], dtype=np.float32)
    blue, green, red = (
        np.clip(cv2.cvtColor(display, cv2.COLOR_LAB2BGR)[0, 0], 0, 1) * 255
    ).round()
    return HoldColor(
        name=name,
        distance=round(distance, 2),
        descriptor=tuple(round(float(v), 2) for v in descriptor),
        rgb=(int(red), int(green), int(blue)),
    )


def polygon_mask(polygon: np.ndarray, shape: tuple[int, int]) -> np.ndarray:
    """Rasterise a polygon given in pixel coordinates into a boolean mask."""
    mask = np.zeros(shape, dtype=np.uint8)
    cv2.fillPoly(mask, [np.round(polygon).astype(np.int32)], 1)
    return mask.astype(bool)


def image_colors(
    image_bgr: np.ndarray, polygons: list[np.ndarray], palette: Palette
) -> list[HoldColor | None]:
    """Colour of every hold of an image, given their polygons in pixel coordinates."""
    shape = image_bgr.shape[:2]
    lab = to_lab(image_bgr)
    masks = [polygon_mask(p, shape) for p in polygons]
    holds_mask = np.zeros(shape, dtype=bool)
    for mask in masks:
        holds_mask |= mask
    cast = wall_cast(lab, holds_mask)
    return [hold_color(lab, mask, cast, palette) for mask in masks]


def draw(
    image_bgr: np.ndarray, polygons: list[np.ndarray], colors: list[HoldColor | None]
) -> np.ndarray:
    """Overlay each hold filled with its detected colour and labelled with its name."""
    fill = image_bgr.copy()
    for polygon, color in zip(polygons, colors):
        if color is None:
            continue
        cv2.fillPoly(fill, [np.round(polygon).astype(np.int32)], color.rgb[::-1])
    out = cv2.addWeighted(fill, 0.65, image_bgr, 0.35, 0)
    scale = max(image_bgr.shape[:2]) / 1600
    for polygon, color in zip(polygons, colors):
        points = np.round(polygon).astype(np.int32)
        cv2.polylines(out, [points], True, (255, 255, 255), max(1, round(2 * scale)))
        if color is None:
            continue
        x, y = points.min(axis=0)
        for thickness, ink in (
            (max(2, round(4 * scale)), (0, 0, 0)),
            (max(1, round(scale)), (255, 255, 255)),
        ):
            cv2.putText(
                out,
                color.name,
                (int(x), int(y) - 4),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.6 * scale,
                ink,
                thickness,
            )
    return out


def evaluate(
    dataset_dir: Path, palette: Palette, splits: tuple[str, ...] = ("val", "test")
) -> dict:
    """Name accuracy on ground-truth masks of a merged dataset (`holds merge` output).

    Only instances whose original class is a colour (`<colour>_hold`, as in the
    Guillaume dataset) are scored.
    """
    import json
    from collections import Counter

    meta = json.loads((dataset_dir / "meta.json").read_text(encoding="utf-8"))
    total, correct, confusion = Counter(), Counter(), Counter()
    for key, entry in meta.items():
        if key.split("/")[0] not in splits:
            continue
        truths = [name.removesuffix("_hold") for name in entry["instances"]]
        if not any(t in palette.names for t in truths):
            continue
        image = cv2.imread(str(dataset_dir / "images" / key))
        height, width = image.shape[:2]
        lines = (
            (dataset_dir / "labels" / key)
            .with_suffix(".txt")
            .read_text(encoding="utf-8")
            .splitlines()
        )
        polygons = [
            np.array(line.split()[1:], dtype=np.float64).reshape(-1, 2)
            * [width, height]
            for line in lines
        ]
        for truth, color in zip(truths, image_colors(image, polygons, palette)):
            if truth not in palette.names or color is None:
                continue
            total[truth] += 1
            correct[truth] += color.name == truth
            if color.name != truth:
                confusion[(truth, color.name)] += 1
    return {
        "accuracy": sum(correct.values()) / max(1, sum(total.values())),
        "holds": sum(total.values()),
        "per_color": {
            name: (correct[name] / total[name], total[name]) for name in sorted(total)
        },
        "confusions": confusion.most_common(5),
    }
