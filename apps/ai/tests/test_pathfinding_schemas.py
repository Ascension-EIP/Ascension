# @date 2026-11-25
# @file test_pathfinding_schemas.py
# @brief Contract tests of the pathfinding schemas (generated models).
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
import json
from pathlib import Path

import pytest
from pydantic import ValidationError

from shared import models
from shared.models import (
    BetaPreference,
    BodyZone,
    ClimberMorphology,
    HoldDetectRequest,
    HoldDetectResult,
    Limb,
    PathfindingComputeRequest,
    PathfindingResult,
    PathfindingStep,
    RoutingKey,
    WallPlane,
)

SCHEMAS = Path(__file__).parents[3] / "schemas"
HOMOGRAPHY = [[1.0, 0.0, 0.0], [0.0, -1.0, 0.0], [0.0, 0.0, 1.0]]
WALL = {"homography": HOMOGRAPHY, "angle_deg": None, "focal_px": 1500.0, "inlier_ratio": 0.8, "model": "m"}
HOLDS = {"left_hand": "a", "right_hand": "b", "left_foot": None, "right_foot": None}
STEP = {
    "index": 1,
    "moved_limb": "left_hand",
    "holds": HOLDS,
    "center_of_mass": {"x": 10.0, "y": 20.0},
    "landmarks": {"nose": {"x": 1.0, "y": 2.0}},
}
PATH = {"image_width": 1080, "image_height": 1920, "wall_angle_deg": None, "steps": [STEP]}


def _schema(name):
    return json.loads((SCHEMAS / f"{name}.schema.json").read_text())


def test_pathfinding_path_validates():
    path = PathfindingResult.model_validate(PATH)
    assert isinstance(path.steps[0], PathfindingStep)
    assert path.steps[0].moved_limb is Limb.LEFT_HAND
    assert path.steps[0].landmarks["nose"].x == 1.0


def test_pathfinding_path_start_step_has_no_moved_limb():
    start = {k: v for k, v in STEP.items() if k != "moved_limb"}
    assert PathfindingResult.model_validate({**PATH, "steps": [start]}).steps[0].moved_limb is None


def test_pathfinding_path_rejects_unknown_limb():
    with pytest.raises(ValidationError):
        PathfindingResult.model_validate({**PATH, "steps": [{**STEP, "moved_limb": "head"}]})


def test_pathfinding_morphology_minimal_and_full():
    assert ClimberMorphology.model_validate({"height_cm": 175}).constraints is None
    full = {
        "height_cm": 175,
        "arm_span_cm": 180,
        "dominant_hand": "ambidextrous",
        "constraints": [{"zone": "left_elbow", "type": "injured"}, {"zone": "right_foot", "type": "missing"}],
    }
    assert ClimberMorphology.model_validate(full).constraints[0].zone is BodyZone.LEFT_ELBOW


def test_pathfinding_morphology_requires_height_and_valid_constraint():
    with pytest.raises(ValidationError):
        ClimberMorphology.model_validate({})
    with pytest.raises(ValidationError):
        ClimberMorphology.model_validate({"height_cm": 175, "constraints": [{"zone": "left_elbow", "type": "sad"}]})


def test_pathfinding_compute_request_preference_is_optional():
    assert PathfindingComputeRequest.model_validate({"job_id": "x"}).preference is None
    assert PathfindingComputeRequest.model_validate({"job_id": "x", "preference": "power"}).preference is BetaPreference.POWER
    assert {p.value for p in BetaPreference} == {"easy", "power", "technique"}
    with pytest.raises(ValidationError):
        PathfindingComputeRequest.model_validate({"job_id": "x", "preference": "fast"})


def test_hold_detect_request_gravity_is_optional():
    assert HoldDetectRequest.model_validate({"job_id": "x", "object_key": "k"}).gravity is None
    assert HoldDetectRequest.model_validate({"job_id": "x", "object_key": "k", "gravity": [0, 9.8, 0]}).gravity


def test_hold_detect_result_wall_is_optional():
    base = {"image_width": 10, "image_height": 10, "holds": []}
    assert HoldDetectResult.model_validate(base).wall is None
    wall = HoldDetectResult.model_validate({**base, "wall": WALL}).wall
    assert isinstance(wall, WallPlane)
    assert wall.angle_deg is None


def test_schema_bounds_that_generated_models_do_not_enforce():
    # quicktype drops minItems/maxItems/minimum/maximum: check them in the schema files instead.
    request = _schema("hold_detect_request")["properties"]["gravity"]
    assert (request["minItems"], request["maxItems"]) == (3, 3)
    wall = _schema("hold_detect_result")["definitions"]["WallPlane"]["properties"]
    homography = wall["homography"]
    assert (homography["minItems"], homography["maxItems"]) == (3, 3)
    assert (homography["items"]["minItems"], homography["items"]["maxItems"]) == (3, 3)
    assert (wall["inlier_ratio"]["minimum"], wall["inlier_ratio"]["maximum"]) == (0, 1)


def test_new_routing_keys():
    assert RoutingKey("pathfinding.compute.requested") is RoutingKey.PATHFINDING_COMPUTE_REQUESTED
    assert RoutingKey("pathfinding.compute.status") is RoutingKey.PATHFINDING_COMPUTE_STATUS


def test_no_renamed_duplicate_types():
    assert [n for n in dir(models) if n[-1:].isdigit()] == []
