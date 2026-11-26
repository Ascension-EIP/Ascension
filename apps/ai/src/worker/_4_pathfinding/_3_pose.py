# @date 2026-11-25
# @file _3_pose.py
# @brief C3: plausible 33-landmark posture from the 4 contacts of a pathfinding step (2-segment inverse kinematics).
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""Posture of the climber from the four contact points of a step.

Wall plane in centimetres, x to the right, y upwards. The climber faces the wall and is seen from behind:
the climber's left side is on the left of the image (smaller x).

The names are kept local (importing the MediaPipe skeleton module would load MediaPipe at start-up);
``tests/test_pathfinding_pose.py`` compares them with ``mediapipe`` ``PoseLandmark``.
"""

import itertools
import math

from shared.models import Limb

Point = tuple[float, float]

#: The 33 MediaPipe pose landmarks, lowercase, in MediaPipe index order.
LANDMARK_NAMES: tuple[str, ...] = (
    "nose",
    "left_eye_inner",
    "left_eye",
    "left_eye_outer",
    "right_eye_inner",
    "right_eye",
    "right_eye_outer",
    "left_ear",
    "right_ear",
    "mouth_left",
    "mouth_right",
    "left_shoulder",
    "right_shoulder",
    "left_elbow",
    "right_elbow",
    "left_wrist",
    "right_wrist",
    "left_pinky",
    "right_pinky",
    "left_index",
    "right_index",
    "left_thumb",
    "right_thumb",
    "left_hip",
    "right_hip",
    "left_knee",
    "right_knee",
    "left_ankle",
    "right_ankle",
    "left_heel",
    "right_heel",
    "left_foot_index",
    "right_foot_index",
)

# Segment lengths as a fraction of the standing height.
# Source: Drillis and Contini, "Body Segment Parameters" (1966), as tabulated in Winter, "Biomechanics and
# Motor Control of Human Movement". Lengths are joint to joint.
UPPER_ARM = 0.186
FOREARM = 0.146
HAND = 0.108
THIGH = 0.245
SHANK = 0.246
SHOULDER_WIDTH = 0.259
HIP_WIDTH = 0.191
#: Shoulder line (0.818) minus hip line (0.530).
TORSO = 0.288
#: Heights above the shoulder midpoint of the face landmarks (eyes at 0.936, nose ~0.905, ears ~0.93, mouth ~0.88).
NOSE_UP = 0.087
EYE_UP = 0.118
EAR_UP = 0.112
MOUTH_UP = 0.062
#: Half-widths of the face landmarks, left of the nose axis for the left side.
EYE_INNER_SIDE = 0.012
EYE_SIDE = 0.025
EYE_OUTER_SIDE = 0.040
EAR_SIDE = 0.065
MOUTH_SIDE = 0.020
#: Foot offsets from the ankle, along the shank direction (towards the toes) and sideways.
HEEL_ALONG = 0.030
HEEL_SIDE = 0.015
TOE_ALONG = 0.085
TOE_SIDE = -0.010

#: Fraction of the full reach used when fitting the torso, so that reachable limbs keep a slight bend.
_FIT_REACH = 0.98
#: Fraction of the full reach under which a limb would fold sharply; the torso is moved away from such contacts.
_FIT_FOLD = 0.6
_FIT_ITERATIONS = 50
#: Barycentre weights of the contacts for the first torso guess (hands carry more than feet).
_HAND_WEIGHT = 1.0
_FOOT_WEIGHT = 0.5
#: A limb without contact hangs at this fraction of its length (a slightly bent, relaxed limb).
_HANG = 0.97
#: Centre of mass: weight of the hip midpoint, the rest goes to the shoulder midpoint (trunk dominates the mass).
_COM_HIP_WEIGHT = 0.6

_ARM_LIMBS = {Limb.LEFT_HAND: "left", Limb.RIGHT_HAND: "right"}
_LEG_LIMBS = {Limb.LEFT_FOOT: "left", Limb.RIGHT_FOOT: "right"}
_SIDE_SIGN = {"left": -1.0, "right": 1.0}


def _add(a: Point, b: Point) -> Point:
    return (a[0] + b[0], a[1] + b[1])


def _sub(a: Point, b: Point) -> Point:
    return (a[0] - b[0], a[1] - b[1])


def _scale(a: Point, k: float) -> Point:
    return (a[0] * k, a[1] * k)


def _unit(a: Point, fallback: Point = (0.0, -1.0)) -> Point:
    n = math.hypot(*a)
    return fallback if n < 1e-9 else (a[0] / n, a[1] / n)


def _ccw(a: Point) -> Point:
    """Rotate a vector 90 degrees counter-clockwise."""
    return (-a[1], a[0])


def _two_link(root: Point, target: Point, l1: float, l2: float, bend: Point) -> tuple[Point, Point]:
    """Two-segment inverse kinematics (law of cosines).

    Args:
        root: Shoulder or hip.
        target: Wanted wrist or ankle.
        l1: Root to middle joint length.
        l2: Middle joint to end length.
        bend: Preferred direction of the middle joint relative to the root-target line.

    Returns:
        ``(middle, end)``. The end is clamped on the sphere of full reach (straight limb pointing at the
        target) when the target is too far, and kept at the minimum folded distance when too close.
    """
    direction = _unit(_sub(target, root))
    d = min(max(math.dist(root, target), abs(l1 - l2) + 1e-6), l1 + l2)
    cos_a = max(-1.0, min(1.0, (l1 * l1 + d * d - l2 * l2) / (2 * l1 * d)))
    a = math.acos(cos_a)
    end = _add(root, _scale(direction, d))
    candidates = []
    for angle in (a, -a):
        c, s = math.cos(angle), math.sin(angle)
        rotated = (direction[0] * c - direction[1] * s, direction[0] * s + direction[1] * c)
        candidates.append(_add(root, _scale(rotated, l1)))
    chord_mid = _scale(_add(root, end), 0.5)
    middle = max(candidates, key=lambda m: _sub(m, chord_mid)[0] * bend[0] + _sub(m, chord_mid)[1] * bend[1])
    return middle, end


def _nearest_in_discs(p: Point, discs: list[tuple[Point, float]]) -> Point | None:
    """Point of the intersection of the discs ``(centre, radius)`` nearest to ``p``; ``None`` if they do not meet.

    The nearest point is ``p`` itself, its projection on one circle, or an intersection of two circles.
    """

    def inside(q: Point) -> bool:
        return all(math.dist(q, c) <= r + 1e-9 for c, r in discs)

    if inside(p):
        return p
    candidates = [_add(c, _scale(_unit(_sub(p, c)), r)) for c, r in discs]
    for (c1, r1), (c2, r2) in itertools.combinations(discs, 2):
        d = math.dist(c1, c2)
        if d < 1e-9 or d > r1 + r2 or d < abs(r1 - r2):
            continue
        a = (r1 * r1 - r2 * r2 + d * d) / (2 * d)
        h = math.sqrt(max(r1 * r1 - a * a, 0.0))
        along = _unit(_sub(c2, c1))
        mid = _add(c1, _scale(along, a))
        candidates += [_add(mid, _scale(_ccw(along), h)), _add(mid, _scale(_ccw(along), -h))]
    feasible = [q for q in candidates if inside(q)]
    return min(feasible, key=lambda q: math.dist(q, p)) if feasible else None


def pose_from_contacts(contacts: dict[Limb, Point | None], height_cm: float) -> dict[str, Point]:
    """Rebuild a plausible 33-landmark posture from the contacts of one pathfinding step.

    Torso heuristic (``ponytail:`` a vertical torso, no lean, no collision test; a pelvis-and-shoulders
    optimisation would be the upgrade): the torso centre starts at the weighted barycentre of the contacts
    (hands weigh 1, feet 0.5), then 50 short iterations move it, by the mean correction, towards the contacts that
    lie beyond 98 % of the reach of their limb and away from those closer than 60 % of it. Shoulders and hips are then placed at fixed offsets from that
    centre. A limb without contact (``None``) hangs relaxed.

    Args:
        contacts: Wall-plane position in cm (y up) of each limb's contact, or ``None`` for a free limb.
        height_cm: Standing height of the climber, in cm.

    Returns:
        The 33 MediaPipe landmark names mapped to ``(x, y)`` in cm, y up.
    """
    h = height_cm
    arm1, arm2, leg1, leg2 = UPPER_ARM * h, FOREARM * h, THIGH * h, SHANK * h
    sh = SHOULDER_WIDTH * h / 2
    hw = HIP_WIDTH * h / 2
    half_torso = TORSO * h / 2
    roots = {
        limb: (_SIDE_SIGN[side] * sh, half_torso) for limb, side in _ARM_LIMBS.items()
    } | {limb: (_SIDE_SIGN[side] * hw, -half_torso) for limb, side in _LEG_LIMBS.items()}
    reach = {limb: (arm1 + arm2 if limb in _ARM_LIMBS else leg1 + leg2) for limb in roots}

    present = {limb: pt for limb, pt in contacts.items() if pt is not None}
    center = (0.0, 0.0)
    if present:
        weights = {limb: _HAND_WEIGHT if limb in _ARM_LIMBS else _FOOT_WEIGHT for limb in present}
        total = sum(weights.values())
        center = (
            sum(weights[limb] * pt[0] for limb, pt in present.items()) / total,
            sum(weights[limb] * pt[1] for limb, pt in present.items()) / total,
        )
    for _ in range(_FIT_ITERATIONS):
        moves = []
        for limb, pt in present.items():
            root = _add(center, roots[limb])
            d = math.dist(root, pt)
            over, under = d - _FIT_REACH * reach[limb], _FIT_FOLD * reach[limb] - d
            if over > 1e-6:
                moves.append(_scale(_unit(_sub(pt, root)), over))
            elif under > 1e-6:
                moves.append(_scale(_unit(_sub(root, pt)), under))
        if not moves:
            break
        center = _add(center, _scale((sum(m[0] for m in moves), sum(m[1] for m in moves)), 1 / len(moves)))
    # The averaged moves can stop short of a torso position that reaches every contact: when one exists, take the
    # nearest one (when none does, the contacts conflict and the averaged compromise stays).
    center = _nearest_in_discs(center, [(_sub(pt, roots[limb]), _FIT_REACH * reach[limb]) for limb, pt in present.items()]) or center

    pose: dict[str, Point] = {}
    shoulder_mid = (center[0], center[1] + half_torso)
    for side, sign in _SIDE_SIGN.items():
        shoulder = _add(center, (sign * sh, half_torso))
        hip = _add(center, (sign * hw, -half_torso))
        pose[f"{side}_shoulder"], pose[f"{side}_hip"] = shoulder, hip

        hand = contacts.get(Limb(f"{side}_hand"))
        if hand is None:
            hand = _add(shoulder, (0.0, -_HANG * (arm1 + arm2)))
        elbow, wrist = _two_link(shoulder, hand, arm1, arm2, (sign, -1.0))
        pose[f"{side}_elbow"], pose[f"{side}_wrist"] = elbow, wrist
        # Palm to the wall: the thumb is on the body side, the pinky outside (left = counter-clockwise outwards).
        fore = _unit(_sub(wrist, elbow))
        out = _ccw(fore) if side == "left" else _scale(_ccw(fore), -1.0)
        hl = HAND * h
        for name, along, lateral in (("pinky", 0.80, 0.25), ("index", 0.95, -0.10), ("thumb", 0.50, -0.30)):
            pose[f"{side}_{name}"] = _add(wrist, _add(_scale(fore, along * hl), _scale(out, lateral * hl)))

        foot = contacts.get(Limb(f"{side}_foot"))
        if foot is None:
            foot = _add(hip, (0.0, -_HANG * (leg1 + leg2)))
        knee, ankle = _two_link(hip, foot, leg1, leg2, (sign, 0.0))
        pose[f"{side}_knee"], pose[f"{side}_ankle"] = knee, ankle
        shin = _unit(_sub(ankle, knee))
        out = _ccw(shin) if side == "left" else _scale(_ccw(shin), -1.0)
        pose[f"{side}_heel"] = _add(ankle, _add(_scale(shin, HEEL_ALONG * h), _scale(out, HEEL_SIDE * h)))
        pose[f"{side}_foot_index"] = _add(ankle, _add(_scale(shin, TOE_ALONG * h), _scale(out, TOE_SIDE * h)))

    def face(up: float, side_offset: float) -> Point:
        return (shoulder_mid[0] + side_offset * h, shoulder_mid[1] + up * h)

    pose["nose"] = face(NOSE_UP, 0.0)
    for name, up, side in (
        ("eye_inner", EYE_UP, EYE_INNER_SIDE),
        ("eye", EYE_UP, EYE_SIDE),
        ("eye_outer", EYE_UP, EYE_OUTER_SIDE),
        ("ear", EAR_UP, EAR_SIDE),
    ):
        pose[f"left_{name}"] = face(up, -side)
        pose[f"right_{name}"] = face(up, side)
    pose["mouth_left"], pose["mouth_right"] = face(MOUTH_UP, -MOUTH_SIDE), face(MOUTH_UP, MOUTH_SIDE)
    return {name: (float(pose[name][0]), float(pose[name][1])) for name in LANDMARK_NAMES}


def center_of_mass(landmarks: dict[str, Point]) -> Point:
    """Approximate centre of mass: weighted mean of the hip and shoulder midpoints.

    The hips weigh 0.6 and the shoulders 0.4 (the pelvis and lower trunk hold more mass than the shoulder
    girdle; limbs are ignored, ``ponytail:`` a segment-mass model would refine it).

    Args:
        landmarks: Output of :func:`pose_from_contacts`.

    Returns:
        ``(x, y)`` in cm, y up.
    """
    w = _COM_HIP_WEIGHT

    def mix(i: int) -> float:
        hips = (landmarks["left_hip"][i] + landmarks["right_hip"][i]) / 2
        shoulders = (landmarks["left_shoulder"][i] + landmarks["right_shoulder"][i]) / 2
        return w * hips + (1 - w) * shoulders

    return (mix(0), mix(1))
