# @date 2026-11-25
# @file _0_wall.py
# @brief Wall geometry from a metric depth map: plane fit, wall angle, pixels to cm homography.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""Wall geometry (ghost step C1).

A metric depth map becomes a point cloud in the OpenCV camera frame (x right, y down, z forward,
metres). A plane fitted on the points outside the holds is the wall, written `n . X + d = 0` with
`n` a unit normal pointing to the camera, so that `d` is the distance from the camera to the plane.
The wall frame has its origin where the optical axis meets the plane, `v` up in the plane and `u`
to the right of the image. The homography maps photo pixels to centimetres in that frame (y up).

The depth map is the z-depth (distance along the optical axis), at the resolution of the image the
focal length refers to. The wall is assumed planar.
"""

import cv2
import numpy as np

from shared.models import WallPlane

RANSAC_ITERATIONS = 200
RANSAC_SAMPLE = 20_000  # points drawn from the valid ones before the RANSAC loop
#: Inlier distance as a share of the median depth: a monocular model is noisy in proportion to the
#: distance (about 1 to 2 % of the depth), so a fixed threshold is too strict far away.
RANSAC_REL_THRESHOLD = 0.012
#: Floor of the inlier distance in metres, for walls seen from very close.
RANSAC_MIN_THRESHOLD_M = 0.02
#: Fewer valid points (outside the holds, finite and positive depth) than this: no reliable plane.
MIN_VALID_POINTS = 1_000
#: Below this share of the whole image covered by inliers there is no wall in view (or the depth is
#: broken): refuse it rather than hand wrong centimetres to the pathfinding. It is measured on the
#: image, not on the valid points, so the floor and the ceiling (about 40 % of a photo) and the
#: holds do not count against a good fit.
MIN_WALL_COVERAGE = 0.2


def unproject(
    depth_m: np.ndarray,
    focal_px: float,
    cx: float | None = None,
    cy: float | None = None,
) -> np.ndarray:
    """Turns a depth map into a point cloud in the OpenCV camera frame.

    Args:
        depth_m: Z-depth in metres, shape (H, W).
        focal_px: Focal length in pixels.
        cx: Optical centre x in pixels, the image centre when None.
        cy: Optical centre y in pixels, the image centre when None.

    Returns:
        Array (H, W, 3) of points in metres (x right, y down, z forward).
    """
    height, width = depth_m.shape
    cx = width / 2 if cx is None else cx
    cy = height / 2 if cy is None else cy
    u, v = np.meshgrid(np.arange(width), np.arange(height))
    return np.stack(
        [(u - cx) / focal_px * depth_m, (v - cy) / focal_px * depth_m, depth_m], axis=-1
    )


def ransac_threshold_m(median_depth_m: float) -> float:
    """Inlier distance for a scene whose median depth is `median_depth_m` (relative, with a floor)."""
    return max(RANSAC_REL_THRESHOLD * median_depth_m, RANSAC_MIN_THRESHOLD_M)


def _plane_through(p: np.ndarray) -> tuple[np.ndarray, float] | None:
    n = np.cross(p[1] - p[0], p[2] - p[0])
    norm = np.linalg.norm(n)
    if norm < 1e-12:
        return None
    n = n / norm
    return n, -float(n @ p[0])


def fit_plane(
    points: np.ndarray,
    valid_mask: np.ndarray,
    threshold_m: float | None = None,
    iterations: int = RANSAC_ITERATIONS,
    seed: int = 0,
) -> tuple[np.ndarray, float, float]:
    """Fits the dominant plane with RANSAC, then refines it by least squares on its inliers.

    Args:
        points: Point cloud (..., 3), metres.
        valid_mask: Boolean mask (...), True for the points to use.
        threshold_m: Distance under which a point is an inlier. Default: `ransac_threshold_m` of
            the median depth of the valid points.
        iterations: RANSAC iterations.
        seed: Seed of the random generator (the result is deterministic).

    Returns:
        (normal, offset, inlier_ratio): unit normal pointing to the camera, `offset` such that
        `normal . X + offset = 0` (so `offset > 0`), and the share of valid points within the
        threshold of the refined plane.

    Raises:
        ValueError: With fewer than 3 valid points or no plane found.
    """
    pts = points[valid_mask].reshape(-1, 3)
    if len(pts) < 3:
        raise ValueError("not enough valid points to fit a plane")
    if threshold_m is None:
        threshold_m = ransac_threshold_m(float(np.median(pts[:, 2])))
    rng = np.random.default_rng(seed)
    sample = (
        pts
        if len(pts) <= RANSAC_SAMPLE
        else pts[rng.choice(len(pts), RANSAC_SAMPLE, replace=False)]
    )

    best, best_count = None, -1
    for _ in range(iterations):
        plane = _plane_through(sample[rng.choice(len(sample), 3, replace=False)])
        if plane is None:
            continue
        count = int((np.abs(sample @ plane[0] + plane[1]) < threshold_m).sum())
        if count > best_count:
            best, best_count = plane, count
    if best is None:
        raise ValueError("no plane found")

    inliers = pts[np.abs(pts @ best[0] + best[1]) < threshold_m]
    centroid = inliers.mean(axis=0)
    normal = np.linalg.svd(inliers - centroid, full_matrices=False)[2][-1]
    if (
        normal @ centroid > 0
    ):  # the camera is at the origin: the normal must point back to it
        normal = -normal
    offset = -float(normal @ centroid)
    ratio = float((np.abs(pts @ normal + offset) < threshold_m).mean())
    return normal, offset, ratio


def wall_angle_deg(normal: np.ndarray, gravity: np.ndarray | None) -> float | None:
    """Angle of the wall to the vertical.

    Args:
        normal: Unit normal of the wall pointing to the camera (and so to the climber).
        gravity: Direction of the floor in the camera frame (any norm), or None.

    Returns:
        0 for a vertical wall, > 0 for an overhang (the wall leans over the climber), < 0 for a
        slab, None when the gravity is unknown.
    """
    if gravity is None:
        return None
    g = np.asarray(gravity, dtype=float)
    return float(
        np.degrees(np.arcsin(np.clip(normal @ g / np.linalg.norm(g), -1.0, 1.0)))
    )


def wall_frame(
    normal: np.ndarray,
    offset: float,
    gravity: np.ndarray | None,
    focal_px: float,
    cx: float,
    cy: float,
) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    """Frame of the wall in camera coordinates (metres).

    The origin is where the ray through the optical (image) centre meets the plane. `v` points up in the
    plane: opposite to the gravity projected on it, or the image up axis projected when the
    gravity is unknown. `u = v x normal` is horizontal and goes to the right of the image.

    Args:
        normal: Unit normal pointing to the camera.
        offset: Plane offset, `normal . X + offset = 0`.
        gravity: Direction of the floor in the camera frame, or None.
        focal_px: Focal length in pixels (the frame is expressed in the camera frame, so the
            intrinsics do not change it; they are kept so every function shares one signature).
        cx: Optical centre x in pixels (idem).
        cy: Optical centre y in pixels (idem).

    Returns:
        (origin, u, v).

    Raises:
        ValueError: If the plane is parallel to the optical axis, or the up direction is along
            the normal (floor wall).
    """
    ray = np.array([0.0, 0.0, 1.0])  # ray through the optical centre
    denom = float(normal @ ray)
    if abs(denom) < 1e-6:
        raise ValueError("the wall is parallel to the optical axis")
    origin = ray * (-offset / denom)
    up = (
        np.array([0.0, -1.0, 0.0])
        if gravity is None
        else -np.asarray(gravity, dtype=float)
    )
    v = up - (up @ normal) * normal
    norm = np.linalg.norm(v)
    if norm < 1e-6 * np.linalg.norm(up):
        raise ValueError("the up direction is along the wall normal")
    v = v / norm
    return origin, np.cross(v, normal), v


def image_to_wall_homography(
    normal: np.ndarray,
    offset: float,
    gravity: np.ndarray | None,
    focal_px: float,
    cx: float,
    cy: float,
) -> np.ndarray:
    """Homography from photo pixels to centimetres in the wall frame (y up).

    A pixel `p` gives the ray `r = K^-1 p` and the plane point `X = -offset * r / (normal . r)`;
    its coordinates are `100 * (X - origin) . (u, v)`. Both are linear in `r` once multiplied by
    `normal . r`, hence a 3x3 matrix.

    Returns:
        Matrix (3, 3) to apply to homogeneous pixels `(x, y, 1)`.
    """
    origin, u, v = wall_frame(normal, offset, gravity, focal_px, cx, cy)
    k_inv = np.array(
        [
            [1 / focal_px, 0, -cx / focal_px],
            [0, 1 / focal_px, -cy / focal_px],
            [0, 0, 1],
        ]
    )
    rows = [-offset * axis - (origin @ axis) * normal for axis in (u, v)]
    return np.vstack([100.0 * np.array(rows), normal]) @ k_inv


def _apply(matrix: np.ndarray, points: np.ndarray) -> np.ndarray:
    pts = np.asarray(points, dtype=float).reshape(-1, 2)
    out = np.column_stack([pts, np.ones(len(pts))]) @ matrix.T
    return out[:, :2] / out[:, 2:3]


def to_wall(homography: np.ndarray, points_px: np.ndarray) -> np.ndarray:
    """Converts photo pixels (N, 2) to centimetres in the wall plane (N, 2), y up."""
    return _apply(homography, points_px)


def to_image(homography: np.ndarray, points_cm: np.ndarray) -> np.ndarray:
    """Converts centimetres in the wall plane (N, 2) back to photo pixels (N, 2)."""
    return _apply(np.linalg.inv(homography), points_cm)


def estimate_wall(
    depth_m: np.ndarray,
    focal_px: float,
    hold_polygons: list[np.ndarray],
    gravity: list[float] | None = None,
    model: str = "",
) -> WallPlane:
    """Estimates the wall plane and the pixels to centimetres homography from a depth map.

    The pixels of the holds are excluded from the fit. The optical centre is the image centre.

    Args:
        depth_m: Metric z-depth map (H, W) in metres.
        focal_px: Focal length in pixels of the depth map resolution.
        hold_polygons: One (n, 2) polygon per hold, in pixels of the depth map.
        gravity: Direction of the floor in the camera frame (3 numbers), or None.
        model: Name of the depth model, stored in the result.

    Returns:
        The wall plane. `angle_deg` is None without gravity.

    Raises:
        ValueError: Bad `gravity` (not 3 finite numbers, or all zero), fewer than
            `MIN_VALID_POINTS` valid points, or inliers covering less than `MIN_WALL_COVERAGE` of
            the image.
    """
    g = None
    if gravity is not None:
        g = np.asarray(gravity, dtype=float)
        if g.shape != (3,) or not np.isfinite(g).all() or not g.any():
            raise ValueError("gravity must be 3 finite numbers, not all zero")

    height, width = depth_m.shape
    holds = np.zeros((height, width), dtype=np.uint8)
    if hold_polygons:
        cv2.fillPoly(
            holds, [np.round(np.asarray(p)).astype(np.int32) for p in hold_polygons], 1
        )
    valid = np.isfinite(depth_m) & (depth_m > 0) & (holds == 0)
    if valid.sum() < MIN_VALID_POINTS:
        raise ValueError(
            f"only {int(valid.sum())} valid points outside the holds, need {MIN_VALID_POINTS}"
        )

    cx, cy = width / 2, height / 2
    normal, offset, ratio = fit_plane(unproject(depth_m, focal_px, cx, cy), valid)
    coverage = ratio * valid.sum() / valid.size
    if coverage < MIN_WALL_COVERAGE:
        raise ValueError(
            f"inliers cover {coverage:.2f} of the image, under {MIN_WALL_COVERAGE}: "
            "no planar wall in view"
        )

    homography = image_to_wall_homography(normal, offset, g, focal_px, cx, cy)
    return WallPlane(
        focal_px=focal_px,
        homography=homography.tolist(),
        inlier_ratio=ratio,
        model=model,
        angle_deg=wall_angle_deg(normal, g),
    )
