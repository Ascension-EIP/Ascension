# @date 2026-11-24
# @file test_holds.py
# @brief Hold detection steps on synthetic inputs: post-processing, colours, chain and render.
# @project Ascension
# @author Livoooo <zarigu92@gmail.com>
# @copyright (c) 2026 Ascension
# @status done
from pathlib import Path

import cv2
import numpy as np
import pytest

from common.utils.errors import PermanentError
from shared.models import HoldDetectResult, HoldType
from worker._3_holds import _0_hold_detect as chain
from worker._3_holds._1_hold_segment import (
    HoldSegmenter,
    Segment,
    letterbox,
    mask_polygon,
    nms,
    select,
)
from worker._3_holds._2_hold_color import PALETTE, WORK_SIZE, hold_colors, name_color

WALL = (150, 150, 150)  # neutral grey wall: no colour cast


def reference_bgr(name: str) -> tuple[int, int, int]:
    """BGR colour of a uniform hold whose descriptor is exactly the palette reference."""
    lab = np.array(PALETTE[name], dtype=np.float32).reshape(1, 1, 3)
    bgr = np.clip(cv2.cvtColor(lab, cv2.COLOR_LAB2BGR)[0, 0], 0, 1) * 255
    return tuple(int(v) for v in bgr.round())


def square(x: float, y: float, size: float = 50) -> np.ndarray:
    return np.array([[x, y], [x + size, y], [x + size, y + size], [x, y + size]], dtype=np.float32)


def wall_with(holds: list[tuple[np.ndarray, tuple[int, int, int]]], shape=(300, 400)) -> np.ndarray:
    image = np.full((*shape, 3), WALL, dtype=np.uint8)
    for polygon, bgr in holds:
        cv2.fillPoly(image, [polygon.round().astype(np.int32)], bgr)
    return image


# --- segmentation post-processing ---------------------------------------------------------


def test_letterbox_keeps_the_ratio_and_centres_the_image():
    padded, gain, (left, top) = letterbox(np.zeros((300, 600, 3), np.uint8), 1024)
    assert padded.shape == (1024, 1024, 3)
    assert gain == pytest.approx(1024 / 600)
    assert (left, top) == (0, (1024 - 512) // 2)


def test_nms_drops_overlapping_boxes_and_keeps_the_best_first():
    boxes = np.array([[0, 0, 10, 10], [0.5, 0.5, 10.5, 10.5], [50, 50, 60, 60]], dtype=np.float32)  # IoU 0.82
    keep = nms(boxes, np.array([0.5, 0.9, 0.8]), iou=0.7)
    assert keep.tolist() == [1, 2]


def raw_output(rows: list[tuple[float, float, float, float, float, float]], coefficients: int = 32) -> np.ndarray:
    """``output0`` of one image for candidates (cx, cy, w, h, score hold, score volume)."""
    data = np.zeros((len(rows), 6 + coefficients), dtype=np.float32)
    data[:, :6] = rows
    return data.T


def test_select_filters_low_scores_and_keeps_overlapping_boxes_of_different_classes():
    raw = raw_output(
        [
            (50, 50, 20, 20, 0.9, 0.0),  # hold
            (51, 51, 20, 20, 0.8, 0.0),  # duplicate of the hold: removed
            (50, 50, 20, 20, 0.0, 0.7),  # volume at the same place: kept (other class)
            (200, 200, 20, 20, 0.05, 0.0),  # below the confidence threshold
        ]
    )
    boxes, scores, classes, coefficients = select(raw, num_classes=2, confidence=0.1)
    assert classes.tolist() == [0, 1]
    assert scores.tolist() == pytest.approx([0.9, 0.7])
    assert boxes[0].tolist() == pytest.approx([40, 40, 60, 60])  # centre/size -> corners
    assert coefficients.shape == (2, 32)


def test_mask_polygon_is_cropped_to_its_box():
    prototypes = np.full((1, 64, 64), 10.0, dtype=np.float32)  # sigmoid ~1 everywhere
    polygon = mask_polygon(np.array([1.0], dtype=np.float32), prototypes, np.array([20, 30, 60, 90]), size=256)
    assert polygon.min(axis=0).tolist() == pytest.approx([20, 30], abs=1)
    assert polygon.max(axis=0).tolist() == pytest.approx([59, 89], abs=1)
    assert mask_polygon(np.array([-1.0], dtype=np.float32), prototypes, np.array([20, 30, 60, 90]), 256) is None


class FakeSession:
    """ONNX session returning one hold at the centre of the letterboxed input."""

    def __init__(self, size: int):
        self.size = size

    def run(self, _outputs, _feed):
        raw = raw_output([(self.size / 2, self.size / 2, 100, 100, 0.95, 0.0)], coefficients=1)
        raw[6] = 1.0  # mask coefficient: the mask is the (positive) prototype, cropped to the box
        return [raw[None], np.full((1, 1, self.size // 4, self.size // 4), 10.0, dtype=np.float32)]


def test_segmenter_maps_coordinates_back_to_the_original_photo():
    segmenter = HoldSegmenter.__new__(HoldSegmenter)
    segmenter.size, segmenter.input_name, segmenter.names = 512, "images", {0: "hold", 1: "volume"}
    segmenter.session = FakeSession(512)
    (segment,) = segmenter(np.zeros((1000, 2000, 3), np.uint8))  # gain 0.256, padded vertically
    assert segment.label == "hold"
    assert segment.confidence == pytest.approx(0.95)
    # A 100 px box at the centre of the input is a ~390 px box at the centre of the photo.
    assert segment.box.tolist() == pytest.approx([804.7, 304.7, 1195.3, 695.3], abs=0.5)
    assert segment.polygon.min(axis=0).tolist() == pytest.approx([804.7, 304.7], abs=5)


def test_segmenter_refuses_a_missing_model(tmp_path):
    with pytest.raises(FileNotFoundError):
        HoldSegmenter(tmp_path / "missing.onnx")


# --- colours ------------------------------------------------------------------------------


def test_palette_names_its_own_references():
    for name, reference in PALETTE.items():
        assert name_color(np.array(reference)) == (name, 0.0)


def test_every_palette_colour_is_recovered_from_an_image():
    names = list(PALETTE)
    polygons = [square(10 + 70 * (i % 5), 10 + 70 * (i // 5)) for i in range(len(names))]
    image = wall_with([(p, reference_bgr(n)) for p, n in zip(polygons, names)])
    assert [c.name for c in hold_colors(image, polygons)] == names


def test_chalk_and_colour_cast_do_not_change_the_name():
    polygons = [square(20, 20, 80), square(150, 20), square(250, 20)]
    names = ["blue", "red", "green"]
    image = wall_with([(p, reference_bgr(n)) for p, n in zip(polygons, names)])
    image[30:70, 30:90] = (235, 235, 235)  # chalk on a large part of the blue hold
    warm = np.clip(image.astype(np.int16) + np.array([-20, 0, 20]), 0, 255).astype(np.uint8)
    assert [c.name for c in hold_colors(warm, polygons)] == names


def test_large_photos_are_measured_at_work_size_and_tiny_holds_are_skipped():
    scale = 2 * WORK_SIZE / 400  # a photo twice the work size
    polygons = [square(20, 20) * scale, square(300, 200, 0.5) * scale]
    image = wall_with([(polygons[0], reference_bgr("yellow"))], shape=(int(300 * scale), int(400 * scale)))
    colors = hold_colors(image, polygons)
    assert colors[0].name == "yellow"
    assert colors[0].rgb[0] > colors[0].rgb[2]  # displayed colour is yellowish (red > blue)
    assert colors[1] is None


# --- chain --------------------------------------------------------------------------------


def test_result_follows_the_holds_table_format():
    polygons = [square(20, 20), square(150, 20)]
    image = wall_with([(p, reference_bgr("blue")) for p in polygons])
    segments = [Segment("hold", 0.91234, np.zeros(4), polygons[0]), Segment("volume", 0.5, np.zeros(4), polygons[1])]
    result = chain.to_result(image, segments)
    assert (result.image_width, result.image_height) == (400, 300)
    assert [h.type for h in result.holds] == [HoldType.UNKNOWN, HoldType.VOLUME]
    first = result.holds[0]
    assert first.confidence == 0.912
    assert first.contour.bbox.model_dump() == {"x": 20, "y": 20, "w": 50, "h": 50}
    assert first.contour.points[0].model_dump() == {"x": 20, "y": 20}
    assert first.color.name == "blue"
    assert chain.render(image, result).shape == image.shape
    HoldDetectResult.model_validate(result.model_dump(mode="json"))  # round-trips through the schema


def test_unreadable_photo_is_a_permanent_error(tmp_path):
    bad = tmp_path / "wall.jpg"
    bad.write_bytes(b"not an image")
    with pytest.raises(PermanentError):
        chain.read_image(bad)


def test_detect_holds_writes_the_render(tmp_path):
    polygon = square(20, 20)
    photo = tmp_path / "wall.jpg"
    cv2.imwrite(str(photo), wall_with([(polygon, reference_bgr("green"))]))

    def segmenter(image, confidence):
        return [Segment("hold", 0.9, np.zeros(4), polygon)]

    result = chain.detect_holds(photo, segmenter, tmp_path / "render.jpg")
    assert len(result.holds) == 1
    assert cv2.imread(str(tmp_path / "render.jpg")).shape == (300, 400, 3)


@pytest.mark.skipif(not Path(chain.__file__).resolve().parents[3].joinpath("resources/holds_seg.onnx").is_file(),
                    reason="resources/holds_seg.onnx is missing")
def test_bundled_model_loads_and_reads_its_classes():
    from worker._3_holds._1_hold_segment import model_path

    segmenter = HoldSegmenter(model_path())
    assert segmenter.names == {0: "hold", 1: "volume"}
    assert segmenter.size == 1024
    assert segmenter(np.full((480, 640, 3), 150, np.uint8)) == []  # an empty grey wall has no hold
