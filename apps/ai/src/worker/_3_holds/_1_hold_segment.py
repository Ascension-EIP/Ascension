# @date 2026-11-24
# @file _1_hold_segment.py
# @brief Hold and volume segmentation of a route photo with the YOLO26-seg model exported to ONNX.
# @project Ascension
# @author Livoooo <zarigu92@gmail.com>
# @copyright (c) 2026 Ascension
# @status done
"""Instance segmentation of holds and volumes with ONNX Runtime (no PyTorch, no ultralytics).

The model is trained and exported by ``apps/holds`` (``holds export``). Its two outputs are:

- ``output0`` (1, 4 + classes + 32, anchors): box (cx, cy, w, h), class scores and mask
  coefficients of every candidate, in the letterboxed input frame;
- ``output1`` (1, 32, H/4, W/4): mask prototypes.

The post-processing reproduces ultralytics ``predict`` (class-aware NMS at IoU 0.7, masks
cropped to their box and thresholded at 0.5), so the worker finds the same holds as the
training tool.
"""

import ast
import os
from dataclasses import dataclass
from pathlib import Path

import cv2
import numpy as np

AI_ROOT = Path(__file__).resolve().parents[3]
DEFAULT_MODEL_PATH = "resources/holds_seg.onnx"
CONFIDENCE = 0.10  # low on purpose: small footholds are often scored low, and the user validates holds
IOU = 0.7
MAX_DETECTIONS = 300
MASK_THRESHOLD = 0.5
PAD_VALUE = 114  # letterbox padding colour used at training time


def model_path() -> str:
    """Model path from ``HOLDS_MODEL_PATH`` (default: bundled model), relative to ``apps/ai``."""
    return str(AI_ROOT / os.environ.get("HOLDS_MODEL_PATH", DEFAULT_MODEL_PATH))


@dataclass
class Segment:
    """One detected instance, in pixels of the original image."""

    label: str  # class name of the model: "hold" or "volume"
    confidence: float
    box: np.ndarray  # (4,) x1, y1, x2, y2
    polygon: np.ndarray  # (n, 2) x, y


def letterbox(image: np.ndarray, size: int) -> tuple[np.ndarray, float, tuple[int, int]]:
    """Resize ``image`` (BGR) to fit a ``size`` square, keeping its ratio, and pad it.

    Returns:
        The padded image, the scale applied and the (left, top) padding.
    """
    height, width = image.shape[:2]
    gain = min(size / height, size / width)
    new_w, new_h = round(width * gain), round(height * gain)
    left, top = (size - new_w) // 2, (size - new_h) // 2
    padded = np.full((size, size, 3), PAD_VALUE, dtype=np.uint8)
    padded[top : top + new_h, left : left + new_w] = cv2.resize(image, (new_w, new_h), interpolation=cv2.INTER_LINEAR)
    return padded, gain, (left, top)


def nms(boxes: np.ndarray, scores: np.ndarray, iou: float) -> np.ndarray:
    """Greedy non-maximum suppression; returns the kept indices, best score first."""
    order = scores.argsort()[::-1]
    areas = (boxes[:, 2] - boxes[:, 0]) * (boxes[:, 3] - boxes[:, 1])
    keep = []
    while order.size:
        best, rest = order[0], order[1:]
        keep.append(best)
        x1 = np.maximum(boxes[best, 0], boxes[rest, 0])
        y1 = np.maximum(boxes[best, 1], boxes[rest, 1])
        x2 = np.minimum(boxes[best, 2], boxes[rest, 2])
        y2 = np.minimum(boxes[best, 3], boxes[rest, 3])
        inter = np.clip(x2 - x1, 0, None) * np.clip(y2 - y1, 0, None)
        order = rest[inter / (areas[best] + areas[rest] - inter + 1e-9) <= iou]
    return np.array(keep, dtype=int)


def select(
    raw: np.ndarray, num_classes: int, confidence: float = CONFIDENCE, iou: float = IOU
) -> tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
    """Keep the confident, non-overlapping candidates of ``output0``.

    Args:
        raw: ``output0`` of one image, shape (4 + num_classes + 32, anchors).

    Returns:
        Boxes (n, 4) as x1, y1, x2, y2, scores (n,), class ids (n,) and mask coefficients (n, 32),
        best score first, in the letterboxed frame.
    """
    candidates = raw.T
    class_scores = candidates[:, 4 : 4 + num_classes]
    classes, scores = class_scores.argmax(axis=1), class_scores.max(axis=1)
    keep = scores >= confidence
    candidates, classes, scores = candidates[keep], classes[keep], scores[keep]
    centers, sizes = candidates[:, :2], candidates[:, 2:4]
    boxes = np.concatenate([centers - sizes / 2, centers + sizes / 2], axis=1)
    # Class-aware NMS: shifting each class far away keeps boxes of different classes apart.
    offset = classes[:, None].astype(np.float32) * (boxes.max(initial=0) + 1)
    kept = nms(boxes + offset, scores, iou)[:MAX_DETECTIONS]
    return boxes[kept], scores[kept], classes[kept], candidates[kept, 4 + num_classes :]


def mask_polygon(coefficients: np.ndarray, prototypes: np.ndarray, box: np.ndarray, size: int) -> np.ndarray | None:
    """Polygon (n, 2) of one instance in the letterboxed frame, or None if its mask is empty."""
    channels, proto_h, proto_w = prototypes.shape
    logits = (coefficients @ prototypes.reshape(channels, -1)).reshape(proto_h, proto_w)
    mask = cv2.resize(1 / (1 + np.exp(-logits)), (size, size), interpolation=cv2.INTER_LINEAR)
    x1, y1, x2, y2 = np.clip(box, 0, size).round().astype(int)
    binary = np.zeros((size, size), dtype=np.uint8)
    binary[y1:y2, x1:x2] = mask[y1:y2, x1:x2] > MASK_THRESHOLD
    contours, _ = cv2.findContours(binary, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    if not contours:
        return None
    return max(contours, key=cv2.contourArea).reshape(-1, 2).astype(np.float32)


class HoldSegmenter:
    """Loads the ONNX model once and segments the holds and volumes of BGR images."""

    def __init__(self, model_path: str | Path):
        import onnxruntime as ort  # lazy: only the hold steps need it

        if not Path(model_path).is_file():
            raise FileNotFoundError(f"hold model not found: {model_path}")
        self.session = ort.InferenceSession(str(model_path), providers=["CPUExecutionProvider"])
        self.input_name = self.session.get_inputs()[0].name
        self.size = int(self.session.get_inputs()[0].shape[-1])
        names = self.session.get_modelmeta().custom_metadata_map.get("names", "{0: 'hold', 1: 'volume'}")
        self.names = ast.literal_eval(names)  # written by ultralytics, e.g. "{0: 'hold', 1: 'volume'}"

    def __call__(self, image: np.ndarray, confidence: float = CONFIDENCE) -> list[Segment]:
        """Segment a BGR image; coordinates of the result are pixels of ``image``."""
        padded, gain, (left, top) = letterbox(image, self.size)
        blob = padded[..., ::-1].transpose(2, 0, 1)[None].astype(np.float32) / 255
        raw, prototypes = self.session.run(None, {self.input_name: blob})
        boxes, scores, classes, coefficients = select(raw[0], len(self.names), confidence)
        shift = np.array([left, top], dtype=np.float32)
        segments = []
        for box, score, cls, coef in zip(boxes, scores, classes, coefficients):
            polygon = mask_polygon(coef, prototypes[0], box, self.size)
            if polygon is None or len(polygon) < 3:
                continue
            segments.append(
                Segment(
                    label=self.names[int(cls)],
                    confidence=float(score),
                    box=(box - np.tile(shift, 2)) / gain,
                    polygon=(polygon - shift) / gain,
                )
            )
        return segments
