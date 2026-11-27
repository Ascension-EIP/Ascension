# @date 2026-11-25
# @file _4_pathfinding.py
# @brief Pathfinding chain: holds of a photo -> wall plane -> beta -> posture of each step in photo pixels.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""Pathfinding chain, without broker, database or storage.

Units: pixels of the photo (y down) on the outside, centimetres in the wall plane (y up) inside.
The CLI sub-commands and the ``pathfinding.compute`` handler both go through these functions.

Beta JSON (output of ``pathfinding-beta``, input of ``pathfinding-pose``)::

    {"height_cm": 175.0, "preference": "easy", "wall_angle_deg": 12.0,
     "steps": [{"holds": {"left_hand": "0", "right_hand": "1", "left_foot": null, "right_foot": null},
                "moved": null}, ...]}

``holds`` maps each limb to a hold id (the index of the hold in the holds file when it has no ``id``);
``moved`` is the limb that changed since the previous step.
"""

import math
from collections.abc import Sequence
from dataclasses import dataclass

import cv2
import numpy as np

from common.utils.errors import PermanentError
from shared.models import (
    BetaPreference,
    ClimberMorphology,
    HoldContour,
    HoldType,
    Limb,
    PathfindingResult,
    PathfindingStep,
    Point2D,
    StepHolds,
    WallPlane,
)
from worker._4_pathfinding._0_wall import estimate_wall, to_image, to_wall
from worker._4_pathfinding._2_beta import (
    LIMBS,
    Hold,
    Step,
    body_from_morphology,
    find_beta,
)
from worker._4_pathfinding._3_pose import center_of_mass, pose_from_contacts

#: Photo-sized skeleton links (MediaPipe landmark names) drawn by `render_pathfinding`.
BONES = (
    ("left_shoulder", "right_shoulder"),
    ("left_hip", "right_hip"),
    ("left_shoulder", "left_hip"),
    ("right_shoulder", "right_hip"),
    ("left_shoulder", "left_elbow"),
    ("left_elbow", "left_wrist"),
    ("right_shoulder", "right_elbow"),
    ("right_elbow", "right_wrist"),
    ("left_hip", "left_knee"),
    ("left_knee", "left_ankle"),
    ("right_hip", "right_knee"),
    ("right_knee", "right_ankle"),
    ("left_ankle", "left_foot_index"),
    ("right_ankle", "right_foot_index"),
)


@dataclass(frozen=True, eq=False)
class PhotoHold:
    """A hold of the photo: id, contour in photo pixels (n, 2), type, usability and start/finish marks."""

    id: str
    polygon: np.ndarray
    type: HoldType = HoldType.UNKNOWN
    usable: bool = True
    start_limbs: int | None = None
    finish_limbs: int | None = None


def validate_gravity(gravity: Sequence[float] | None) -> None:
    """Check the shape of an optional gravity vector (the generated models do not enforce it).

    Raises:
        PermanentError: Not 3 finite numbers, or all zero.
    """
    if gravity is None:
        return
    try:
        g = np.asarray(gravity, dtype=float)
    except (TypeError, ValueError) as exc:
        raise PermanentError("gravity must be 3 finite numbers") from exc
    if g.shape != (3,) or not np.isfinite(g).all() or not g.any():
        raise PermanentError("gravity must be 3 finite numbers, not all zero")


def validate_wall(wall: WallPlane) -> np.ndarray:
    """Return the homography of ``wall`` as a (3, 3) array, after checking its shape.

    Raises:
        PermanentError: The homography is not a finite, invertible 3x3 matrix.
    """
    try:
        matrix = np.array(wall.homography, dtype=float)
    except ValueError as exc:  # ragged rows
        raise PermanentError("wall homography must be a 3x3 matrix") from exc
    if matrix.shape != (3, 3):
        raise PermanentError(f"wall homography must be a 3x3 matrix, got shape {matrix.shape}")
    if not np.isfinite(matrix).all() or abs(np.linalg.det(matrix)) < 1e-12:
        raise PermanentError("wall homography must be finite and invertible")
    return matrix


def estimate_photo_wall(
    image_bgr: np.ndarray, hold_polygons: list[np.ndarray], estimator, gravity: Sequence[float] | None = None, model: str = ""
) -> WallPlane:
    """Wall plane of a photo: metric depth, then plane fit outside the holds.

    The estimator returns the depth at the size of the photo and the focal length in pixels of that
    photo, so the depth map, the focal length and the polygons (photo pixels) share one scale. The focal
    length is estimated by the model: the worker has no reliable EXIF focal length to give it.
    Invalid depth pixels (NaN) are ignored by the plane fit.

    Raises:
        ValueError: The depth map is not the size of the photo, or the wall cannot be fitted (see `estimate_wall`).
    """
    depth, focal_px = estimator(image_bgr)
    if depth.shape != image_bgr.shape[:2]:
        raise ValueError(f"depth map size {depth.shape} differs from the photo size {image_bgr.shape[:2]}")
    return estimate_wall(depth, focal_px, hold_polygons, None if gravity is None else list(gravity), model)


def photo_holds_from_dicts(rows: list[dict]) -> list[PhotoHold]:
    """Build the holds from rows ``{id?, type?, contour, usable?, start_limbs?, finish_limbs?}``.

    The same shape comes from the database and from the holds JSON of the CLI (a ``HoldDetectResult``
    whose holds may carry marks). Without ``id`` the id is the index of the row.

    Raises:
        PermanentError: A contour, type or mark is invalid.
    """
    holds = []
    for index, row in enumerate(rows):
        try:
            contour = HoldContour.model_validate(row["contour"])
            kind = HoldType(row.get("type") or "unknown")
        except (KeyError, ValueError) as exc:
            raise PermanentError(f"hold {row.get('id', index)}: invalid contour or type") from exc
        start, finish = row.get("start_limbs"), row.get("finish_limbs")
        if start is not None and not 1 <= start <= 4 or finish is not None and not 1 <= finish <= 2:
            raise PermanentError(f"hold {row.get('id', index)}: start_limbs must be 1-4 and finish_limbs 1-2")
        holds.append(
            PhotoHold(
                str(row.get("id", index)),
                np.array([(p.x, p.y) for p in contour.points], dtype=float),
                kind,
                row.get("usable", True),
                start,
                finish,
            )
        )
    return holds


def _centroid(points: np.ndarray) -> np.ndarray:
    m = cv2.moments(points.astype(np.float32))
    return np.array([m["m10"] / m["m00"], m["m01"] / m["m00"]]) if m["m00"] else points.mean(axis=0)


def _area(points: np.ndarray) -> float:
    x, y = points[:, 0], points[:, 1]
    return abs(float(np.dot(x, np.roll(y, -1)) - np.dot(y, np.roll(x, -1)))) / 2


def build_holds(
    holds_px: list[PhotoHold], homography: np.ndarray, feet_free: bool, selected_ids: Sequence[str] | None
) -> list[Hold]:
    """Holds of the beta search, in the wall plane (cm, y up).

    The route is the selected holds (all the usable ones when none is selected) plus the holds carrying a
    start or finish mark. With ``feet_free`` the other usable holds of the photo are added as foot holds.
    Centre and area come from the homography, so perspective is accounted for.

    Raises:
        PermanentError: Duplicate ids, or no usable hold.
    """
    if len({h.id for h in holds_px}) != len(holds_px):
        raise PermanentError("duplicate hold ids")
    usable = [h for h in holds_px if h.usable]
    chosen = set(selected_ids or ())
    route = [h for h in usable if h.id in chosen or h.start_limbs or h.finish_limbs] if chosen else usable
    if not route:
        raise PermanentError("no usable hold on the route")
    on_route = {h.id for h in route}
    built = []
    for hold in usable:
        if hold.id not in on_route and not feet_free:
            continue
        center = to_wall(homography, _centroid(hold.polygon))[0]
        area = _area(to_wall(homography, hold.polygon))
        built.append(
            Hold(
                hold.id,
                float(center[0]),
                float(center[1]),
                area,
                hold.type,
                hold.start_limbs,
                hold.finish_limbs,
                hand=hold.id in on_route,
                foot=True,
            )
        )
    return built


def find_beta_for_route(
    holds_px: list[PhotoHold],
    wall: WallPlane,
    feet_free: bool,
    selected_ids: Sequence[str] | None,
    morphology: ClimberMorphology,
    preference: BetaPreference,
) -> list[Step]:
    """Holds of the photo and morphology to the beta (see `find_beta`).

    Raises:
        PermanentError: Invalid wall or no usable hold.
        NoBetaError: No beta exists.
    """
    holds = build_holds(holds_px, validate_wall(wall), feet_free, selected_ids)
    return find_beta(holds, body_from_morphology(morphology), preference, wall.angle_deg)


def pose_steps(steps: list[Step], holds_px: list[PhotoHold], wall: WallPlane, height_cm: float, image_size: tuple[int, int]) -> PathfindingResult:
    """Posture of every step of a beta, in photo pixels.

    Args:
        steps: Output of `find_beta_for_route`.
        holds_px: The holds of the photo (the beta refers to their ids).
        wall: Wall plane; its homography moves the postures from cm back to pixels.
        height_cm: Climber height.
        image_size: Photo ``(width, height)``.

    Raises:
        PermanentError: Invalid wall, a step holds an unknown hold, or a posture falls outside the finite plane.
    """
    homography = validate_wall(wall)
    centers = {h.id: to_wall(homography, _centroid(h.polygon))[0] for h in holds_px}
    out = []
    for index, step in enumerate(steps):
        try:
            contacts = {limb: None if step.holds.get(limb) is None else tuple(centers[step.holds[limb]]) for limb in LIMBS}
        except KeyError as exc:
            raise PermanentError(f"step {index}: unknown hold {exc.args[0]}") from exc
        pose = pose_from_contacts(contacts, height_cm)
        names = list(pose)
        points = to_image(homography, np.array([*pose.values(), center_of_mass(pose)]))
        if not np.isfinite(points).all():
            raise PermanentError(f"step {index}: the posture does not project on the photo")
        out.append(
            PathfindingStep(
                index=index,
                holds=StepHolds(**{limb.value: step.holds.get(limb) for limb in LIMBS}),
                moved_limb=step.moved,
                landmarks={n: Point2D(x=round(float(x), 2), y=round(float(y), 2)) for n, (x, y) in zip(names, points[:-1], strict=True)},
                center_of_mass=Point2D(x=round(float(points[-1][0]), 2), y=round(float(points[-1][1]), 2)),
            )
        )
    return PathfindingResult(image_width=image_size[0], image_height=image_size[1], wall_angle_deg=wall.angle_deg, steps=out)


def compute_pathfinding(
    holds_px: list[PhotoHold],
    wall: WallPlane,
    feet_free: bool,
    selected_ids: Sequence[str] | None,
    morphology: ClimberMorphology,
    preference: BetaPreference,
    image_size: tuple[int, int],
) -> PathfindingResult:
    """Whole chain: holds, wall and morphology to the pathfinding result in photo pixels.

    Raises:
        PermanentError: Invalid input (wall, holds).
        NoBetaError: No beta exists.
    """
    steps = find_beta_for_route(holds_px, wall, feet_free, selected_ids, morphology, preference)
    return pose_steps(steps, holds_px, wall, morphology.height_cm, image_size)


def beta_to_json(steps: list[Step], height_cm: float, preference: BetaPreference, wall_angle_deg: float | None = None) -> dict:
    """Beta as the JSON passed from ``pathfinding-beta`` to ``pathfinding-pose`` (format in the module docstring)."""
    return {
        "height_cm": height_cm,
        "preference": preference.value,
        "wall_angle_deg": wall_angle_deg,
        "steps": [{"holds": {limb.value: step.holds.get(limb) for limb in LIMBS}, "moved": step.moved and step.moved.value} for step in steps],
    }


def beta_from_json(data: dict) -> tuple[list[Step], float]:
    """Read the beta JSON back: the steps and the height of the climber.

    Raises:
        PermanentError: Missing or malformed keys.
    """
    try:
        height = float(data["height_cm"])
        if not math.isfinite(height) or height <= 0:
            raise ValueError("height_cm")
        steps = [
            Step({limb: s["holds"][limb.value] for limb in LIMBS}, None if s["moved"] is None else Limb(s["moved"]))
            for s in data["steps"]
        ]
    except (KeyError, TypeError, ValueError) as exc:
        raise PermanentError(f"invalid beta JSON: {exc!r}") from exc
    return steps, height


def render_pathfinding(image: np.ndarray, path: PathfindingResult) -> list[np.ndarray]:
    """One copy of the photo per step, each with only that step's skeleton and a ``step i/n`` caption.

    The colour goes from blue (start) to red (finish) so the pictures stay comparable side by side.
    """
    scale = max(image.shape[:2]) / 1000
    count = max(1, len(path.steps) - 1)
    frames = []
    for step in path.steps:
        out = image.copy()
        t = step.index / count
        color = (int(255 * (1 - t)), 60, int(255 * t))  # BGR
        pts = {n: (round(p.x), round(p.y)) for n, p in step.landmarks.items()}
        for a, b in BONES:
            cv2.line(out, pts[a], pts[b], color, max(1, round(2 * scale)), cv2.LINE_AA)
        for limb, hold in step.holds.model_dump().items():
            if hold is not None:
                name = limb.replace("_hand", "_wrist").replace("_foot", "_ankle")
                cv2.circle(out, pts[name], max(2, round(4 * scale)), color, -1, cv2.LINE_AA)
        label = f"step {step.index + 1}/{len(path.steps)}"
        org, font, size = (round(20 * scale), round(image.shape[0] * 0.9)), cv2.FONT_HERSHEY_SIMPLEX, scale
        cv2.putText(out, label, org, font, size, (0, 0, 0), max(1, round(6 * scale)), cv2.LINE_AA)  # outline, readable on any photo
        cv2.putText(out, label, org, font, size, (255, 255, 255), max(1, round(2 * scale)), cv2.LINE_AA)
        frames.append(out)
    return frames
