# @date 2026-11-25
# @file test_ghost_pose.py
# @brief Unit tests of the ghost posture reconstruction (inverse kinematics from 4 contacts).
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
import math

from shared.models import Limb
from worker._4_ghost._3_pose import LANDMARK_NAMES, center_of_mass, pose_from_contacts

H = 175.0
ARM1, ARM2 = 0.186 * H, 0.146 * H
LEG1, LEG2 = 0.245 * H, 0.246 * H

#: Usual position: hands at shoulder height or above, feet below.
CONTACTS = {
    Limb.LEFT_HAND: (-25.0, 165.0),
    Limb.RIGHT_HAND: (25.0, 165.0),
    Limb.LEFT_FOOT: (-15.0, 15.0),
    Limb.RIGHT_FOOT: (15.0, 15.0),
}


def dist(a, b):
    return math.hypot(a[0] - b[0], a[1] - b[1])


def test_landmark_names_match_mediapipe():
    from mediapipe.tasks.python import vision

    expected = [vision.PoseLandmark(i).name.lower() for i in range(len(vision.PoseLandmark))]
    assert list(LANDMARK_NAMES) == expected
    assert len(LANDMARK_NAMES) == 33


def test_pose_has_exactly_the_33_landmarks():
    pose = pose_from_contacts(CONTACTS, H)
    assert set(pose) == set(LANDMARK_NAMES)
    assert len(pose) == 33


def test_reachable_contacts_are_hit_and_segments_keep_their_length():
    pose = pose_from_contacts(CONTACTS, H)
    for limb, wrist in (("left", Limb.LEFT_HAND), ("right", Limb.RIGHT_HAND)):
        assert dist(pose[f"{limb}_wrist"], CONTACTS[wrist]) < 1.0
        assert abs(dist(pose[f"{limb}_shoulder"], pose[f"{limb}_elbow"]) - ARM1) < 0.5
        assert abs(dist(pose[f"{limb}_elbow"], pose[f"{limb}_wrist"]) - ARM2) < 0.5
    for limb, foot in (("left", Limb.LEFT_FOOT), ("right", Limb.RIGHT_FOOT)):
        assert dist(pose[f"{limb}_ankle"], CONTACTS[foot]) < 1.0
        assert abs(dist(pose[f"{limb}_hip"], pose[f"{limb}_knee"]) - LEG1) < 0.5
        assert abs(dist(pose[f"{limb}_knee"], pose[f"{limb}_ankle"]) - LEG2) < 0.5


def test_out_of_reach_contact_gives_a_straight_limb_towards_it():
    contacts = {**CONTACTS, Limb.RIGHT_HAND: (0.0, 330.0), Limb.RIGHT_FOOT: (0.0, 0.0)}
    pose = pose_from_contacts(contacts, H)
    for side, root, mid, end, total, target in (
        ("hand", "right_shoulder", "right_elbow", "right_wrist", ARM1 + ARM2, contacts[Limb.RIGHT_HAND]),
        ("foot", "right_hip", "right_knee", "right_ankle", LEG1 + LEG2, contacts[Limb.RIGHT_FOOT]),
    ):
        r, m, e = pose[root], pose[mid], pose[end]
        assert abs(dist(r, e) - total) < 0.5, side
        assert abs(dist(r, m) + dist(m, e) - total) < 0.5, side
        to_target = (target[0] - r[0], target[1] - r[1])
        to_end = (e[0] - r[0], e[1] - r[1])
        cos = (to_target[0] * to_end[0] + to_target[1] * to_end[1]) / (math.hypot(*to_target) * math.hypot(*to_end))
        assert cos > 0.999, side


def test_limb_without_contact_hangs():
    pose = pose_from_contacts({**CONTACTS, Limb.LEFT_HAND: None, Limb.LEFT_FOOT: None}, H)
    assert abs(pose["left_wrist"][0] - pose["left_shoulder"][0]) < 5.0
    assert pose["left_wrist"][1] < pose["left_shoulder"][1] - 0.8 * (ARM1 + ARM2)
    assert abs(pose["left_ankle"][0] - pose["left_hip"][0]) < 5.0
    assert pose["left_ankle"][1] < pose["left_hip"][1] - 0.8 * (LEG1 + LEG2)


def test_no_contact_at_all_still_gives_a_pose():
    pose = pose_from_contacts({limb: None for limb in Limb}, H)
    assert len(pose) == 33
    assert pose["left_wrist"][1] < pose["left_shoulder"][1]


def test_vertical_ordering_of_the_body():
    pose = pose_from_contacts(CONTACTS, H)
    assert pose["nose"][1] > max(pose["left_shoulder"][1], pose["right_shoulder"][1])
    assert min(pose["left_shoulder"][1], pose["right_shoulder"][1]) > max(pose["left_hip"][1], pose["right_hip"][1])
    assert pose["left_ear"][1] > pose["left_shoulder"][1]


def test_left_is_on_the_left_of_the_image():
    pose = pose_from_contacts(CONTACTS, H)
    for part in ("shoulder", "elbow", "wrist", "hip", "knee", "ankle", "heel", "foot_index", "ear", "thumb", "pinky"):
        assert pose[f"left_{part}"][0] < pose[f"right_{part}"][0], part
    assert pose["left_eye"][0] < pose["nose"][0] < pose["right_eye"][0]


def test_elbows_and_knees_bend_outwards():
    pose = pose_from_contacts(CONTACTS, H)
    for side, sign in (("left", -1), ("right", 1)):
        for root, mid, end in (("shoulder", "elbow", "wrist"), ("hip", "knee", "ankle")):
            chord_x = (pose[f"{side}_{root}"][0] + pose[f"{side}_{end}"][0]) / 2
            assert sign * (pose[f"{side}_{mid}"][0] - chord_x) > 1.0, (side, mid)


def test_torso_keeps_limbs_from_folding_on_close_contacts():
    pose = pose_from_contacts(CONTACTS, H)
    for side in ("left", "right"):
        assert dist(pose[f"{side}_shoulder"], pose[f"{side}_wrist"]) > 0.5 * (ARM1 + ARM2)
        assert dist(pose[f"{side}_hip"], pose[f"{side}_ankle"]) > 0.5 * (LEG1 + LEG2)


def test_pose_is_deterministic():
    assert pose_from_contacts(CONTACTS, H) == pose_from_contacts(dict(CONTACTS), H)


def test_all_coordinates_are_finite_floats():
    pose = pose_from_contacts({**CONTACTS, Limb.RIGHT_HAND: (0.0, 600.0)}, 160.0)
    assert all(math.isfinite(c) for xy in pose.values() for c in xy)


def test_center_of_mass_is_between_hips_and_shoulders():
    pose = pose_from_contacts(CONTACTS, H)
    x, y = center_of_mass(pose)
    hips_y = (pose["left_hip"][1] + pose["right_hip"][1]) / 2
    shoulders_y = (pose["left_shoulder"][1] + pose["right_shoulder"][1]) / 2
    assert hips_y < y < shoulders_y
    assert pose["left_hip"][0] < x < pose["right_hip"][0]


def test_center_of_mass_is_closer_to_the_hips():
    pose = {name: (0.0, 0.0) for name in LANDMARK_NAMES}
    pose["left_hip"] = pose["right_hip"] = (10.0, 0.0)
    pose["left_shoulder"] = pose["right_shoulder"] = (10.0, 100.0)
    assert center_of_mass(pose) == (10.0, 40.0)


def _reachable_contacts(rng, height):
    """Contacts generated from a real torso position: each is inside the reach of its limb, so a fit exists."""
    half_torso, sh, hw = 0.288 * height / 2, 0.259 * height / 2, 0.191 * height / 2
    centre = (rng.uniform(0, 200), rng.uniform(80, 300))
    roots = {
        Limb.LEFT_HAND: (centre[0] - sh, centre[1] + half_torso),
        Limb.RIGHT_HAND: (centre[0] + sh, centre[1] + half_torso),
        Limb.LEFT_FOOT: (centre[0] - hw, centre[1] - half_torso),
        Limb.RIGHT_FOOT: (centre[0] + hw, centre[1] - half_torso),
    }
    contacts = {}
    for limb, (rx, ry) in roots.items():
        reach = (0.186 + 0.146 if "hand" in limb.value else 0.245 + 0.246) * height
        angle, radius = rng.uniform(0, 2 * math.pi), rng.uniform(0.7, 0.96) * reach
        contacts[limb] = (rx + radius * math.cos(angle), ry + radius * math.sin(angle))
    return contacts


def test_contacts_that_a_torso_can_reach_are_all_hit():
    import random

    rng = random.Random(7)
    worst = 0.0
    for _ in range(200):
        contacts = _reachable_contacts(rng, H)
        pose = pose_from_contacts(contacts, H)
        for limb, end in ((Limb.LEFT_HAND, "left_wrist"), (Limb.RIGHT_HAND, "right_wrist"), (Limb.LEFT_FOOT, "left_ankle"), (Limb.RIGHT_FOOT, "right_ankle")):
            worst = max(worst, dist(pose[end], contacts[limb]))
    assert worst < 1.5, f"a limb stays {worst:.1f} cm away from a contact its torso could reach"
