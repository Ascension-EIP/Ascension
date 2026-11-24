# @date 2026-11-24
# @file _0_hold_detect.py
# @brief Chain of the hold steps: read the photo, segment the holds, measure their colour.
# @project Ascension
# @author Livoooo <zarigu92@gmail.com>
# @copyright (c) 2026 Ascension
# @status done
"""Chain of the hold steps: segmentation, then colour. No broker, database or storage."""

from pathlib import Path

import cv2
import numpy as np

from common.utils.errors import PermanentError
from shared.models import (
    DetectedHold,
    HoldBox,
    HoldContour,
    HoldDetectResult,
    HoldPoint,
    HoldType,
)
from worker._3_holds._1_hold_segment import CONFIDENCE, HoldSegmenter, Segment
from worker._3_holds._2_hold_color import hold_colors

#: Model class -> `hold_type`. The model does not classify grips yet: every hold is `unknown`.
LABEL_TYPES = {"volume": HoldType.VOLUME}


def read_image(path: str | Path) -> np.ndarray:
    """Read a photo as BGR, applying its EXIF orientation.

    Raises:
        PermanentError: The file is not a readable image.
    """
    image = cv2.imread(str(path), cv2.IMREAD_COLOR)
    if image is None:
        raise PermanentError(f"unreadable image: {Path(path).name}")
    return image


def _contour(polygon: np.ndarray) -> HoldContour:
    x1, y1 = polygon.min(axis=0)
    x2, y2 = polygon.max(axis=0)
    return HoldContour(
        points=[HoldPoint(x=round(float(x), 1), y=round(float(y), 1)) for x, y in polygon],
        bbox=HoldBox(
            x=round(float(x1), 1), y=round(float(y1), 1), w=round(float(x2 - x1), 1), h=round(float(y2 - y1), 1)
        ),
    )


def to_result(image: np.ndarray, segments: list[Segment]) -> HoldDetectResult:
    """Build the result of one photo from its segments (colours are measured here)."""
    height, width = image.shape[:2]
    colors = hold_colors(image, [s.polygon for s in segments])
    holds = [
        DetectedHold(
            type=LABEL_TYPES.get(s.label, HoldType.UNKNOWN),
            confidence=round(s.confidence, 3),
            contour=_contour(s.polygon),
            color=color,
        )
        for s, color in zip(segments, colors)
    ]
    return HoldDetectResult(image_width=width, image_height=height, holds=holds)


def render(image: np.ndarray, result: HoldDetectResult) -> np.ndarray:
    """Draw every hold filled with its measured colour and labelled with its colour name."""
    fill = image.copy()
    polygons = [np.array([(p.x, p.y) for p in h.contour.points], dtype=np.int32) for h in result.holds]
    for hold, poly in zip(result.holds, polygons):
        if hold.color is not None:
            cv2.fillPoly(fill, [poly], tuple(hold.color.rgb[::-1]))
    out = cv2.addWeighted(fill, 0.65, image, 0.35, 0)
    scale = max(image.shape[:2]) / 1600
    for hold, poly in zip(result.holds, polygons):
        cv2.polylines(out, [poly], True, (255, 255, 255), max(1, round(2 * scale)))
        label = "volume" if hold.type == HoldType.VOLUME else (hold.color.name if hold.color else "?")
        x, y = int(hold.contour.bbox.x), int(hold.contour.bbox.y)
        for thickness, ink in ((max(2, round(4 * scale)), (0, 0, 0)), (max(1, round(scale)), (255, 255, 255))):
            cv2.putText(out, label, (x, y - 4), cv2.FONT_HERSHEY_SIMPLEX, 0.6 * scale, ink, thickness)
    return out


def detect_holds(
    image_path: str | Path,
    segmenter: HoldSegmenter,
    render_path: str | Path | None = None,
    confidence: float = CONFIDENCE,
) -> HoldDetectResult:
    """Detect the holds and volumes of a route photo and measure their colour.

    Raises:
        PermanentError: The photo cannot be read.
    """
    image = read_image(image_path)
    result = to_result(image, segmenter(image, confidence))
    if render_path:
        cv2.imwrite(str(render_path), render(image, result))
    return result
