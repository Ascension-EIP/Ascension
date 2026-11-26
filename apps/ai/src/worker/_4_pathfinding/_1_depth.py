# @date 2026-11-25
# @file _1_depth.py
# @brief Metric monocular depth of a route photo with MoGe-2 (ViT-S) on ONNX Runtime, and its error measurement.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""Metric depth of a single photo with ONNX Runtime (no PyTorch).

The model is MoGe-2 ViT-S (MIT, https://huggingface.co/Ruicheng/moge-2-vits-normal-onnx), downloaded by
``scripts/download-depth-model.sh``. The ONNX file only holds the raw forward pass: its outputs are an
*affine* point map (up to a depth shift and the focal), a mask and a metric scale. The post-processing of
the reference ``MoGeModel.infer`` (``recover_focal_shift``) is redone here with numpy, without scipy.

Conventions: camera frame of OpenCV (x right, y down, z forward), depth in metres along z, pixels of the
original photo. Pixels the model flags as invalid are ``NaN``.
"""

import json
import math
import os
from pathlib import Path

import cv2
import numpy as np
import onnxruntime as ort

AI_ROOT = Path(__file__).resolve().parents[3]
DEFAULT_MODEL_PATH = "resources/moge-2-vits-normal.onnx"
MAX_SIDE = 640  # the photo is shrunk to this long side before the model; the depth is resized back
NUM_TOKENS = 1800  # base ViT tokens (range 1200-3600 in the reference): more is finer and slower on CPU
MASK_THRESHOLD = 0.5
FIT_SIZE = 64  # the focal / shift fit runs on a 64x64 nearest downsampling, like the reference
# ponytail: 69 deg is a typical phone main camera (26 mm equivalent), used only when the focal fit fails; read EXIF instead.
DEFAULT_HFOV_DEG = 69.0
SHIFT_GRID = np.geomspace(1e-3, 1e3, 256)  # candidate z shifts, measured from the nearest point of the map


def depth_model_path() -> str:
    """Model path from ``DEPTH_MODEL_PATH`` (default: downloaded model), relative to ``apps/ai``."""
    return str(AI_ROOT / os.environ.get("DEPTH_MODEL_PATH", DEFAULT_MODEL_PATH))


def view_plane_uv(width: int, height: int) -> np.ndarray:
    """Normalised pixel grid (H, W, 2) of the reference: pixel offset from the centre over half the diagonal."""
    aspect = width / height
    span_x, span_y = aspect / math.sqrt(1 + aspect**2), 1 / math.sqrt(1 + aspect**2)
    u = np.linspace(-span_x * (width - 1) / width, span_x * (width - 1) / width, width)
    v = np.linspace(-span_y * (height - 1) / height, span_y * (height - 1) / height, height)
    return np.stack(np.meshgrid(u, v), axis=-1)


def solve_shift_focal(uv: np.ndarray, xyz: np.ndarray, focal: float | None = None) -> tuple[float, float] | None:
    """Fit ``focal * xy / (z + shift) = uv`` on a point map known up to a z shift.

    The focal has a closed form for a given shift, so only the shift is searched (log grid, then
    golden-section refinement), on the domain where every ``z + shift`` is positive.

    Args:
        uv: (n, 2) normalised pixel coordinates.
        xyz: (n, 3) affine points.
        focal: Known focal relative to half the diagonal; estimated when None.

    Returns:
        ``(shift, focal)``, or None when there are too few points or no finite fit.
    """
    if len(uv) < 2:
        return None
    xy, z = xyz[:, :2].astype(np.float64), xyz[:, 2].astype(np.float64)
    uv = uv.astype(np.float64)
    z_min = z.min()

    def fit(t: float) -> tuple[float, float]:
        proj = xy / (z + t - z_min)[:, None]
        f = focal if focal is not None else (proj * uv).sum() / max((proj**2).sum(), 1e-12)
        return float(((f * proj - uv) ** 2).sum()), float(f)

    costs = np.array([fit(t)[0] for t in SHIFT_GRID])
    best = int(costs.argmin())
    low, high = SHIFT_GRID[max(best - 1, 0)], SHIFT_GRID[min(best + 1, len(SHIFT_GRID) - 1)]
    ratio = (math.sqrt(5) - 1) / 2
    for _ in range(60):
        a, b = high - ratio * (high - low), low + ratio * (high - low)
        low, high = (low, b) if fit(a)[0] < fit(b)[0] else (a, high)
    t = (low + high) / 2
    f = fit(t)[1]
    if not (np.isfinite(f) and f > 0):
        return None
    return float(t - z_min), f


class DepthEstimator:
    """Loads the ONNX model once and estimates the metric depth of BGR photos."""

    def __init__(self, model_path: str | Path):
        if not Path(model_path).is_file():
            raise FileNotFoundError(f"depth model not found: {model_path}")
        self.session = ort.InferenceSession(str(model_path), providers=["CPUExecutionProvider"])

    def __call__(self, image_bgr: np.ndarray, focal_px: float | None = None) -> tuple[np.ndarray, float]:
        """Estimate the depth of a BGR photo.

        Args:
            image_bgr: Photo (H, W, 3) uint8.
            focal_px: Focal length in pixels of ``image_bgr`` when known (EXIF). Otherwise the model
                estimates it; when that fit fails, the default horizontal field of view is used.

        Returns:
            The depth in metres (H, W) float32 at the size of ``image_bgr`` (NaN where invalid), and the
            focal length used, in pixels of ``image_bgr``.
        """
        height, width = image_bgr.shape[:2]
        diagonal = math.hypot(width, height)
        gain = min(1.0, MAX_SIDE / max(height, width))
        small = cv2.resize(image_bgr, (round(width * gain), round(height * gain)), interpolation=cv2.INTER_AREA)
        blob = np.ascontiguousarray(small[..., ::-1].transpose(2, 0, 1)[None], dtype=np.float32) / 255
        points, _normal, mask, scale = self.session.run(None, {"image": blob, "num_tokens": np.array(NUM_TOKENS, np.int64)})
        points, valid = points[0], mask[0] > MASK_THRESHOLD

        small_h, small_w = points.shape[:2]
        fit_size = (min(FIT_SIZE, small_w), min(FIT_SIZE, small_h))
        keep = cv2.resize(valid.astype(np.uint8), fit_size, interpolation=cv2.INTER_NEAREST) > 0
        uv = cv2.resize(view_plane_uv(small_w, small_h), fit_size, interpolation=cv2.INTER_NEAREST)[keep]
        sample = cv2.resize(points, fit_size, interpolation=cv2.INTER_NEAREST)[keep]

        known = None if focal_px is None else 2 * focal_px / diagonal  # relative to half the diagonal
        fit = solve_shift_focal(uv, sample, known)
        if fit is None:  # no valid pixel, or a degenerate fit: fall back on the default field of view
            known = 2 * (width / 2 / math.tan(math.radians(DEFAULT_HFOV_DEG / 2))) / diagonal
            fit = solve_shift_focal(uv, sample, known) or (0.0, known)
        shift, relative_focal = fit

        z = points[..., 2].astype(np.float64) + shift
        depth = np.where(valid & (z > 0), z * float(scale[0]), np.nan).astype(np.float32)
        if depth.shape != (height, width):
            depth = cv2.resize(depth, (width, height), interpolation=cv2.INTER_LINEAR)
        return depth, relative_focal * diagonal / 2


def render_depth(depth_m: np.ndarray) -> np.ndarray:
    """Colour a depth map (TURBO, near to far over its own range) as a BGR image; invalid pixels are black."""
    valid = np.isfinite(depth_m)
    if not valid.any():
        return np.zeros((*depth_m.shape, 3), np.uint8)
    low, high = float(depth_m[valid].min()), float(depth_m[valid].max())
    scaled = np.where(valid, (depth_m - low) / max(high - low, 1e-6), 0)
    image = cv2.applyColorMap((scaled * 255).astype(np.uint8), cv2.COLORMAP_TURBO)
    image[~valid] = 0
    return image


def _distance_cm(depth_m: np.ndarray, focal_px: float, a: list[float], b: list[float]) -> float | None:
    """3D distance in cm between two pixels of the photo, or None when one has no valid depth."""
    height, width = depth_m.shape
    points = []
    for x, y in (a, b):
        z = depth_m[min(max(round(y), 0), height - 1), min(max(round(x), 0), width - 1)]
        if not np.isfinite(z):
            return None
        points.append([(x - width / 2) / focal_px * z, (y - height / 2) / focal_px * z, z])
    return float(np.linalg.norm(np.subtract(*points))) * 100


def evaluate_depth(dataset_dir: str | Path, estimator) -> dict:
    """Relative error of the estimated 3D distances between annotated pixel pairs of wall photos.

    ``dataset_dir`` holds the photos and ``annotations.json``: a list of
    ``{"image": name, "pairs": [{"a": [x, y], "b": [x, y], "distance_cm": real distance}]}``
    (pixels on the wall, distance measured on the wall by the team).

    Args:
        dataset_dir: Folder of the photos and the annotations.
        estimator: Callable ``(image_bgr) -> (depth_m, focal_px)``, such as `DepthEstimator`.

    Returns:
        ``images`` (name, focal, per-pair relative errors, mean and median), then the global ``pairs``,
        ``skipped`` (pairs on a pixel without valid depth), ``mean`` and ``median`` (NaN without pair).
    """
    dataset_dir = Path(dataset_dir)
    annotations = json.loads((dataset_dir / "annotations.json").read_text(encoding="utf-8"))
    images, all_errors, skipped = [], [], 0
    for entry in annotations:
        image = cv2.imread(str(dataset_dir / entry["image"]), cv2.IMREAD_COLOR)
        if image is None:
            raise ValueError(f"unreadable image: {entry['image']}")
        depth, focal = estimator(image)
        errors = []
        for pair in entry["pairs"]:
            estimated = _distance_cm(depth, focal, pair["a"], pair["b"])
            if estimated is None:
                skipped += 1
            else:
                errors.append(abs(estimated - pair["distance_cm"]) / pair["distance_cm"])
        all_errors += errors
        images.append(
            {
                "image": entry["image"],
                "focal_px": float(focal),
                "errors": errors,
                "mean": float(np.mean(errors)) if errors else math.nan,
                "median": float(np.median(errors)) if errors else math.nan,
            }
        )
    return {
        "images": images,
        "pairs": len(all_errors),
        "skipped": skipped,
        "mean": float(np.mean(all_errors)) if all_errors else math.nan,
        "median": float(np.median(all_errors)) if all_errors else math.nan,
    }
