# @date 2026-11-25
# @file test_ghost_chain.py
# @brief Unit tests of the ghost chain: photo holds -> beta -> posture in photo pixels (synthetic photo, known homography).
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
import math

import numpy as np
import pytest

from common.utils.errors import PermanentError
from shared.models import (
    BetaPreference,
    GhostMorphology,
    GhostPath,
    HoldType,
    Limb,
    WallPlane,
)
from worker._4_ghost import _4_ghost as chain
from worker._4_ghost._0_wall import to_image, to_wall
from worker._4_ghost._2_beta import NoBetaError
from worker._4_ghost._3_pose import LANDMARK_NAMES, pose_from_contacts

SCALE = 0.5  # cm per pixel
WIDTH, HEIGHT = 400, 800  # photo: 200 cm x 400 cm of wall
HOMOGRAPHY = [[SCALE, 0, 0], [0, -SCALE, HEIGHT * SCALE], [0, 0, 1]]  # pixels (y down) -> cm (y up)
WALL = WallPlane(focal_px=1000.0, homography=HOMOGRAPHY, inlier_ratio=0.95, model="fake", angle_deg=12.0)
MORPHOLOGY = GhostMorphology(height_cm=175, arm_span_cm=178)


def square(x_cm: float, y_cm: float, side_cm: float = 10.0) -> np.ndarray:
    """Pixel polygon of a square hold centred on a point of the wall (cm, y up)."""
    half = side_cm / 2
    corners = np.array([[x_cm - half, y_cm - half], [x_cm + half, y_cm - half], [x_cm + half, y_cm + half], [x_cm - half, y_cm + half]])
    return to_image(np.array(HOMOGRAPHY), corners)


def ladder(n: int = 12, marks: dict | None = None) -> list[chain.PhotoHold]:
    """Holds one above the other, 20 cm apart, zig-zagging around x = 100 cm."""
    return [
        chain.PhotoHold(str(i), square(90 + 20 * (i % 2), 20 + 20 * i), HoldType.UNKNOWN, **(marks or {}).get(i, {})) for i in range(n)
    ]


def compute(holds, selected=None, feet_free=False, preference=BetaPreference.EASY, morphology=MORPHOLOGY):
    return chain.compute_ghost(holds, WALL, feet_free, selected, morphology, preference, (WIDTH, HEIGHT))


# --- holds in the wall plane ---------------------------------------------------------------


def test_hold_centre_and_area_come_from_the_homography():
    (hold,) = chain.build_holds([chain.PhotoHold("a", square(60, 120, 10), HoldType.JUG)], np.array(HOMOGRAPHY), False, None)
    assert (hold.x, hold.y) == pytest.approx((60, 120), abs=0.01)
    assert hold.area_cm2 == pytest.approx(100, rel=0.001)
    assert hold.type == HoldType.JUG and hold.hand and hold.foot


def test_without_selection_every_usable_hold_is_the_route_and_unusable_ones_are_dropped():
    holds = ladder(3)
    holds[1] = chain.PhotoHold("1", holds[1].polygon, HoldType.UNKNOWN, usable=False)
    built = chain.build_holds(holds, np.array(HOMOGRAPHY), False, None)
    assert [h.id for h in built] == ["0", "2"]


def test_a_selection_keeps_only_the_selected_holds_and_the_marked_ones():
    holds = ladder(4, {3: {"finish_limbs": 2}})
    built = chain.build_holds(holds, np.array(HOMOGRAPHY), False, ["0", "1"])
    assert [h.id for h in built] == ["0", "1", "3"]  # marks make a hold part of the route
    assert built[2].finish_limbs == 2


def test_feet_free_adds_the_other_usable_holds_as_foot_only():
    holds = ladder(4)
    built = {h.id: h for h in chain.build_holds(holds, np.array(HOMOGRAPHY), True, ["1", "2"])}
    assert sorted(built) == ["0", "1", "2", "3"]
    assert built["1"].hand and built["1"].foot
    assert not built["0"].hand and built["0"].foot and not built["3"].hand and built["3"].foot


def test_no_usable_hold_is_a_permanent_error():
    with pytest.raises(PermanentError, match="no usable hold"):
        chain.build_holds([chain.PhotoHold("a", square(60, 120), HoldType.UNKNOWN, usable=False)], np.array(HOMOGRAPHY), False, None)


def test_duplicate_hold_ids_are_rejected():
    holds = [chain.PhotoHold("a", square(60, 120), HoldType.UNKNOWN)] * 2
    with pytest.raises(PermanentError, match="duplicate"):
        chain.build_holds(holds, np.array(HOMOGRAPHY), False, None)


# --- the chain -----------------------------------------------------------------------------


def test_compute_ghost_returns_a_valid_path_in_photo_pixels():
    path = compute(ladder())
    GhostPath.model_validate(path.model_dump())  # the generated model accepts it
    assert (path.image_width, path.image_height, path.wall_angle_deg) == (WIDTH, HEIGHT, 12.0)
    assert len(path.steps) >= 4
    assert [s.index for s in path.steps] == list(range(len(path.steps)))
    assert path.steps[0].moved_limb is None and all(s.moved_limb for s in path.steps[1:])
    for step in path.steps:
        assert set(step.landmarks) == set(LANDMARK_NAMES)
        assert all(math.isfinite(p.x) and math.isfinite(p.y) for p in step.landmarks.values())


def test_the_chain_places_the_posture_of_the_contacts_on_the_photo():
    """Each step is `pose_from_contacts` of the hold centres, moved back to pixels by the homography."""
    holds = ladder()
    path = compute(holds)
    matrix = np.array(HOMOGRAPHY)
    centres = {h.id: to_wall(matrix, h.polygon.mean(axis=0, keepdims=True))[0] for h in holds}
    for step in path.steps:
        contacts = {Limb(limb): None if hold is None else tuple(centres[hold]) for limb, hold in step.holds.model_dump().items()}
        expected = pose_from_contacts(contacts, MORPHOLOGY.height_cm)
        for name, (x, y) in expected.items():
            px = to_image(matrix, np.array([[x, y]]))[0]
            assert (step.landmarks[name].x, step.landmarks[name].y) == pytest.approx(tuple(px), abs=0.01)


def test_at_the_start_both_wrists_are_on_the_start_hold():
    holds = ladder()
    first = compute(holds).steps[0]
    centre = holds[int(first.holds.left_hand)].polygon.mean(axis=0)
    for wrist in ("left_wrist", "right_wrist"):
        p = first.landmarks[wrist]
        assert math.dist((p.x, p.y), centre) < 3  # pixels (1.5 cm)


def test_the_climber_goes_up_in_the_photo():
    path = compute(ladder())
    first, last = path.steps[0], path.steps[-1]
    assert last.center_of_mass.y < first.center_of_mass.y  # pixels, y down


def test_the_holds_of_a_step_are_the_ids_of_the_input():
    path = compute(ladder())
    used = {v for s in path.steps for v in s.holds.model_dump().values() if v}
    assert used and used <= {str(i) for i in range(12)}


def test_marks_choose_the_start_and_the_finish():
    holds = ladder(6, {2: {"start_limbs": 2}, 4: {"finish_limbs": 2}})
    path = compute(holds)
    assert path.steps[0].holds.left_hand == path.steps[0].holds.right_hand == "2"
    assert path.steps[-1].holds.left_hand == path.steps[-1].holds.right_hand == "4"


def test_a_missing_passage_raises_no_beta_with_the_holds_around_the_gap():
    holds = [chain.PhotoHold("low", square(100, 20), HoldType.UNKNOWN), chain.PhotoHold("high", square(100, 380), HoldType.UNKNOWN)]
    with pytest.raises(NoBetaError) as error:
        compute(holds)
    assert set(error.value.hold_ids) == {"low", "high"}


def test_the_preference_reaches_the_search():
    holds = ladder()
    easy = compute(holds, preference=BetaPreference.EASY)
    power = compute(holds, preference=BetaPreference.POWER)
    assert len(power.steps) <= len(easy.steps)


def test_beta_then_pose_equals_compute_ghost():
    holds = ladder()
    steps = chain.find_ghost_beta(holds, WALL, False, None, MORPHOLOGY, BetaPreference.EASY)
    assert chain.pose_steps(steps, holds, WALL, MORPHOLOGY.height_cm, (WIDTH, HEIGHT)) == compute(holds)


def test_beta_json_round_trip():
    holds = ladder()
    steps = chain.find_ghost_beta(holds, WALL, False, None, MORPHOLOGY, BetaPreference.EASY)
    data = chain.beta_to_json(steps, MORPHOLOGY.height_cm, BetaPreference.EASY)
    back, height = chain.beta_from_json(data)
    assert back == steps and height == 175


@pytest.mark.parametrize("bad", [{}, {"height_cm": 175}, {"height_cm": 175, "steps": [{"holds": {"left_hand": "1"}}]}, {"height_cm": -1, "steps": []}])
def test_a_malformed_beta_json_is_a_permanent_error(bad):
    with pytest.raises(PermanentError):
        chain.beta_from_json(bad)


# --- shape validation ----------------------------------------------------------------------


@pytest.mark.parametrize(
    "homography",
    [
        [[1, 0, 0], [0, 1, 0]],  # 2x3
        [[1, 0, 0], [0, 1, 0], [0, 0]],  # ragged
        [[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0]],
        [[1, 0, 0], [0, 1, 0], [0, 0, float("nan")]],
        [[1, 0, 0], [0, 1, 0], [0, 0, float("inf")]],
        [[1, 2, 3], [2, 4, 6], [1, 2, 3]],  # singular
    ],
)
def test_a_wall_whose_homography_is_not_an_invertible_3x3_is_rejected(homography):
    wall = WALL.model_copy(update={"homography": homography})
    with pytest.raises(PermanentError, match="homography"):
        chain.validate_wall(wall)


def test_a_valid_wall_gives_its_matrix():
    assert chain.validate_wall(WALL).shape == (3, 3)


@pytest.mark.parametrize("gravity", [[0, 1], [0, 1, 0, 0], [0, 0, 0], [0, float("nan"), 0], [float("inf"), 0, 0]])
def test_gravity_must_be_three_finite_numbers_not_all_zero(gravity):
    with pytest.raises(PermanentError, match="gravity"):
        chain.validate_gravity(gravity)


def test_gravity_is_optional_and_accepts_a_good_vector():
    chain.validate_gravity(None)
    chain.validate_gravity([0.0, 9.8, 0.3])


# --- wall of a photo -----------------------------------------------------------------------


def fronto_parallel_depth(width=1000, height=800, z=3.0):
    return np.full((height, width), z, np.float32)


class FakeEstimator:
    def __init__(self, depth, focal=1000.0):
        self.depth, self.focal, self.calls = depth, focal, []

    def __call__(self, image, focal_px=None):
        self.calls.append(focal_px)
        return self.depth, self.focal


def test_wall_of_a_photo_measures_in_centimetres_and_ignores_nan_depth():
    depth = fronto_parallel_depth()
    depth[:, 700:] = np.nan  # pixels the model judged invalid
    estimator = FakeEstimator(depth)
    image = np.zeros((800, 1000, 3), np.uint8)
    wall = chain.estimate_photo_wall(image, [np.array([[100, 100], [200, 100], [200, 200], [100, 200]])], estimator, [0.0, 9.8, 0.0], "fake")
    assert estimator.calls == [None]  # the focal is estimated by the model, never forced
    assert wall.model == "fake" and wall.focal_px == 1000.0
    h = chain.validate_wall(wall)
    a, b = to_wall(h, np.array([[100.0, 400.0], [900.0, 400.0]]))
    assert np.linalg.norm(a - b) == pytest.approx(240, rel=0.01)  # 800 px at 3 m with f = 1000 px
    assert wall.angle_deg == pytest.approx(0, abs=0.5)


def test_a_depth_map_of_another_size_than_the_photo_is_refused():
    estimator = FakeEstimator(fronto_parallel_depth(500, 400))
    with pytest.raises(ValueError, match="size"):
        chain.estimate_photo_wall(np.zeros((800, 1000, 3), np.uint8), [], estimator, None, "fake")


# --- render --------------------------------------------------------------------------------


def test_render_draws_the_skeletons_on_a_copy_of_the_photo():
    path = compute(ladder())
    photo = np.full((HEIGHT, WIDTH, 3), 120, np.uint8)
    out = chain.render_ghost(photo, path)
    assert out.shape == photo.shape and not np.array_equal(out, photo)
    assert (photo == 120).all()  # the input is untouched
