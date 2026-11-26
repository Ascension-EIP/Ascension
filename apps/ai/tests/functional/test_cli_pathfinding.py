# @date 2026-11-25
# @file test_cli_pathfinding.py
# @brief Runs the pathfinding sub-commands of `worker` as real processes: the steps without model, and the real models on a real photo.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
import json

import pytest

from shared.models import PathfindingResult
from tests.functional.test_cli import APP, run
from tests.test_pathfinding_cli import HEIGHT, WIDTH, holds_json

pytestmark = pytest.mark.functional

PHOTO = APP.parents[1] / "docs" / "Ascension" / "resources" / "images" / "deck" / "climb_olivier.jpeg"
MODELS = [APP / "resources" / "holds_seg.onnx", APP / "resources" / "moge-2-vits-normal.onnx"]
WALL = {"focal_px": 400.0, "homography": [[0.75, 0, 0], [0, -0.75, 600], [0, 0, 1]], "inlier_ratio": 1.0, "model": "hand-written", "angle_deg": 0.0}


def test_beta_then_pose_run_without_any_model(tmp_path):
    """The two last steps only need the holds JSON with a wall: no model, no network."""
    holds = tmp_path / "holds_wall.json"
    holds.write_text(json.dumps({**holds_json({0: {"start_limbs": 2}, 11: {"finish_limbs": 2}}), "wall": WALL}))
    beta, path = tmp_path / "beta.json", tmp_path / "path.json"
    r = run("pathfinding-beta", "--input", holds, "--out", beta, "--preference", "technique")
    assert r.returncode == 0, r.stderr
    assert json.loads(beta.read_text())["preference"] == "technique"
    r = run("pathfinding-pose", "--input", beta, "--holds", holds, "--out", path)
    assert r.returncode == 0, r.stderr
    result = PathfindingResult.model_validate_json(path.read_text())
    assert (result.image_width, result.image_height) == (WIDTH, HEIGHT) and len(result.steps) >= 4


def test_pathfinding_beta_without_a_wall_gives_a_clean_error(tmp_path):
    holds = tmp_path / "holds.json"
    holds.write_text(json.dumps(holds_json()))
    r = run("pathfinding-beta", "--input", holds, "--out", tmp_path / "beta.json")
    assert r.returncode == 1 and "pathfinding-wall" in r.stdout + r.stderr and "Traceback" not in r.stderr


@pytest.mark.skipif(not all(m.is_file() for m in MODELS) or not PHOTO.is_file(), reason="real models or photo missing")
def test_pathfinding_wall_with_the_real_models_on_a_real_photo_ends_cleanly(tmp_path):
    """The photo is a communication shot (climber in the foreground): the plane may not be found, and then
    the command must say so and write nothing; when it is found, the output must be a valid result."""
    out = tmp_path / "holds_wall.json"
    r = run("pathfinding-wall", "--image", PHOTO, "--out", out, "--gravity", 0, 1, 0)
    assert "Traceback" not in r.stderr
    if r.returncode == 0:
        from shared.models import HoldDetectResult

        assert HoldDetectResult.model_validate_json(out.read_text()).wall is not None
    else:
        assert r.returncode == 1 and not out.exists() and "not planar" in r.stdout + r.stderr.replace("\n", " ")
