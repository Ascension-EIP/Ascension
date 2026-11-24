# @date 2026-11-24
# @file _2_hold_color.py
# @brief Dominant colour of each detected hold, named after a reference palette.
# @project Ascension
# @author Livoooo <zarigu92@gmail.com>
# @copyright (c) 2026 Ascension
# @status done
"""Dominant colour of each hold (pipeline step B3).

Hold pixels are summarised in CIELAB space, where lightness and colour are separate:

- the mask is eroded so that wall pixels on the hold border are ignored;
- chalk desaturates holds, so the colour (a*, b*) is the median of the 10 % most saturated pixels;
- the lightness is the 25th percentile, chalk being lighter than the hold;
- the colour cast of the photo is removed using the wall around the holds.

The descriptor is named after the closest colour of `PALETTE`. Measured on the Guillaume and
eeqyl datasets: ~83 % correct names in a calibrated gym, ~60 % in an unseen one (red/orange,
green/yellow and chalked black/cream are the usual confusions). The displayed `rgb` is reliable;
the `name` is a hint for the user.
"""

import cv2
import numpy as np

from shared.models import HoldColor

#: Images are analysed with their longest side at this size (the palette was measured at it).
WORK_SIZE = 1600
MIN_PIXELS = 20
EROSION_RATIO = 0.1  # erosion radius, relative to the square root of the mask area
KEEP_AFTER_EROSION = 0.3  # fall back to the raw mask when erosion removes more than this
SATURATED_PERCENTILE = 90
LIGHTNESS_PERCENTILE = 25
LIGHTNESS_WEIGHT = 0.5  # lightness counts half as much as colour in the distance

#: Reference descriptors (L, a, b): median per colour on the train splits of the Guillaume
#: (polygon masks) and eeqyl (ellipses inscribed in boxes) datasets, see apps/holds.
PALETTE: dict[str, tuple[float, float, float]] = {
    "black": (17.5, -0.2, -0.4),
    "blue": (30.5, 3.6, -30.6),
    "brown": (41.0, 5.9, 20.8),
    "cream": (40.6, 1.8, 9.3),
    "green": (34.8, -25.5, 21.1),
    "orange": (33.0, 36.7, 26.3),
    "pink": (37.2, 46.5, -5.0),
    "purple": (24.5, 11.1, -15.8),
    "red": (41.5, 32.3, 12.2),
    "white": (51.0, -1.4, 11.1),
    "yellow": (54.7, -3.2, 59.7),
}
_NAMES = list(PALETTE)
_REFERENCES = np.array([PALETTE[n] for n in _NAMES], dtype=np.float64)
_WEIGHTS = np.array([LIGHTNESS_WEIGHT, 1.0, 1.0])


def name_color(descriptor: np.ndarray) -> tuple[str, float]:
    """Closest palette colour of a (L, a, b) descriptor, and its weighted distance."""
    distances = np.linalg.norm((_REFERENCES - descriptor) * _WEIGHTS, axis=1)
    best = int(np.argmin(distances))
    return _NAMES[best], float(distances[best])


def _hold_pixels(lab: np.ndarray, mask: np.ndarray) -> np.ndarray:
    """Lab pixels covered by ``mask`` (uint8), without the hold border."""
    radius = max(1, int(EROSION_RATIO * np.sqrt(mask.sum())))
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (2 * radius + 1, 2 * radius + 1))
    eroded = cv2.erode(mask, kernel)
    keep = eroded if eroded.sum() > KEEP_AFTER_EROSION * mask.sum() else mask
    return lab[keep.astype(bool)]


def _describe(pixels: np.ndarray, cast: np.ndarray) -> HoldColor | None:
    if len(pixels) < MIN_PIXELS:
        return None
    chroma = np.hypot(pixels[:, 1], pixels[:, 2])
    saturated = pixels[chroma >= np.percentile(chroma, SATURATED_PERCENTILE)]
    a, b = np.median(saturated[:, 1:], axis=0)
    lightness = float(np.percentile(pixels[:, 0], LIGHTNESS_PERCENTILE))
    name, distance = name_color(np.array([lightness, a - cast[0], b - cast[1]]))
    display = np.array([[[np.median(saturated[:, 0]), a, b]]], dtype=np.float32)
    blue, green, red = (np.clip(cv2.cvtColor(display, cv2.COLOR_LAB2BGR)[0, 0], 0, 1) * 255).round()
    return HoldColor(name=name, rgb=[int(red), int(green), int(blue)], distance=round(distance, 2))


def hold_colors(image: np.ndarray, polygons: list[np.ndarray]) -> list[HoldColor | None]:
    """Colour of every hold of a BGR image (None for a hold too small to measure).

    Args:
        image: BGR photo, any size.
        polygons: One (n, 2) polygon per hold, in pixels of ``image``.
    """
    scale = min(1.0, WORK_SIZE / max(image.shape[:2]))
    if scale < 1:
        image = cv2.resize(image, None, fx=scale, fy=scale, interpolation=cv2.INTER_AREA)
    lab = cv2.cvtColor(image.astype(np.float32) / 255, cv2.COLOR_BGR2LAB)
    height, width = lab.shape[:2]
    points = [np.round(np.asarray(p, dtype=np.float64) * scale).astype(np.int32) for p in polygons]

    holds_mask = np.zeros((height, width), dtype=np.uint8)
    cv2.fillPoly(holds_mask, points, 1)
    background = lab[holds_mask == 0]
    cast = np.median(background[:, 1:], axis=0) if len(background) else np.zeros(2)

    colors = []
    for poly in points:
        x, y, w, h = cv2.boundingRect(poly)
        # Margin larger than the erosion radius: cv2.erode treats pixels outside the crop as
        # part of the mask, so a crop tight on the hold would leave its border uneroded.
        margin = int(EROSION_RATIO * np.sqrt(w * h)) + 2
        x2, y2 = min(x + w + margin, width), min(y + h + margin, height)
        x, y = max(x - margin, 0), max(y - margin, 0)
        if x2 <= x or y2 <= y:
            colors.append(None)
            continue
        local = np.zeros((y2 - y, x2 - x), dtype=np.uint8)
        cv2.fillPoly(local, [poly - [x, y]], 1)
        colors.append(_describe(_hold_pixels(lab[y:y2, x:x2], local), cast))
    return colors
