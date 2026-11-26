# @date 2026-11-25
# @file test_ghost_cli.py
# @brief The ghost sub-commands of `worker` run in-process with fake models: each step, the chain of the steps, and `ghost`.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
import json

import cv2
import numpy as np
import pytest

from shared.models import GhostPath, HoldDetectResult
from worker import cli, runtime
from worker._3_holds._1_hold_segment import Segment

WIDTH, HEIGHT = 400, 800
FOCAL = 400.0  # a plane at 3 m: 0.75 cm per pixel


class FakeDepth:
    """A wall facing the camera at 3 m."""

    calls = 0

    def __call__(self, image, focal_px=None):
        FakeDepth.calls += 1
        return np.full(image.shape[:2], 3.0, np.float32), FOCAL


class FakeSegmenter:
    """Finds the squares of the ladder."""

    def __call__(self, image, confidence=0.1):
        return [Segment("hold", 0.9, np.array([0, 0, 1, 1.0]), np.array(p, float)) for p in LADDER]


def square(cx, cy, half=7):
    return [[cx - half, cy - half], [cx + half, cy - half], [cx + half, cy + half], [cx - half, cy + half]]


#: 12 holds 25 px (19 cm) apart, zig-zagging, the lowest at the bottom of the photo.
LADDER = [square(190 + 20 * (i % 2), 760 - 25 * i) for i in range(12)]


def holds_json(marks: dict | None = None) -> dict:
    holds = []
    for i, polygon in enumerate(LADDER):
        xs, ys = [p[0] for p in polygon], [p[1] for p in polygon]
        box = {"x": min(xs), "y": min(ys), "w": max(xs) - min(xs), "h": max(ys) - min(ys)}
        holds.append(
            {"type": "unknown", "confidence": 0.9, "contour": {"points": [{"x": x, "y": y} for x, y in polygon], "bbox": box}}
            | (marks or {}).get(i, {})
        )
    return {"image_width": WIDTH, "image_height": HEIGHT, "holds": holds}


@pytest.fixture(autouse=True)
def fake_models(monkeypatch):
    FakeDepth.calls = 0
    monkeypatch.setattr(runtime, "get_depth_estimator", lambda: FakeDepth())
    monkeypatch.setattr(runtime, "get_hold_segmenter", lambda: FakeSegmenter())


@pytest.fixture
def photo(tmp_path):
    path = tmp_path / "wall.png"
    cv2.imwrite(str(path), np.full((HEIGHT, WIDTH, 3), 140, np.uint8))
    return path


@pytest.fixture
def holds_file(tmp_path):
    path = tmp_path / "holds.json"
    path.write_text(json.dumps(holds_json({0: {"start_limbs": 2}, 11: {"finish_limbs": 2}})))
    return path


def worker(*args) -> int:
    """Run the CLI in-process; returns the exit code."""
    try:
        cli.main([str(a) for a in args])
    except SystemExit as e:
        return int(e.code or 0)
    return 0


def load(path) -> dict:
    return json.loads(path.read_text())


@pytest.fixture
def holds_wall(tmp_path, photo, holds_file):
    out = tmp_path / "holds_wall.json"
    assert worker("ghost-wall", "--image", photo, "--holds", holds_file, "--out", out) == 0
    return out


# --- ghost-wall ----------------------------------------------------------------------------


def test_ghost_wall_adds_the_wall_to_the_holds_and_keeps_their_marks(holds_wall):
    data = load(holds_wall)
    result = HoldDetectResult.model_validate(data)  # a valid HoldDetectResult
    assert result.wall is not None and result.wall.model == "moge-2-vits-normal" and result.wall.angle_deg is None
    assert len(data["holds"]) == 12 and data["holds"][0]["start_limbs"] == 2 and data["holds"][11]["finish_limbs"] == 2
    assert FakeDepth.calls == 1


def test_ghost_wall_with_gravity_gives_the_angle(tmp_path, photo, holds_file):
    out = tmp_path / "out.json"
    assert worker("ghost-wall", "--image", photo, "--holds", holds_file, "--out", out, "--gravity", 0, 9.8, 0) == 0
    assert load(out)["wall"]["angle_deg"] == pytest.approx(0, abs=0.5)


def test_ghost_wall_detects_the_holds_when_none_are_given(tmp_path, photo):
    out = tmp_path / "out.json"
    assert worker("ghost-wall", "--image", photo, "--out", out) == 0
    result = HoldDetectResult.model_validate(load(out))
    assert len(result.holds) == 12 and result.wall is not None


@pytest.mark.parametrize("gravity", [("0", "nan", "0"), ("0", "0", "0")])
def test_ghost_wall_rejects_a_bad_gravity(tmp_path, photo, holds_file, gravity):
    out = tmp_path / "out.json"
    assert worker("ghost-wall", "--image", photo, "--holds", holds_file, "--out", out, "--gravity", *gravity) == 1
    assert not out.exists()


def test_ghost_wall_rejects_holds_of_another_photo_size(tmp_path, photo):
    other = tmp_path / "other.json"
    other.write_text(json.dumps({**holds_json(), "image_width": 10}))
    out = tmp_path / "out.json"
    assert worker("ghost-wall", "--image", photo, "--holds", other, "--out", out) == 1 and not out.exists()


def test_ghost_wall_fails_cleanly_when_no_plane_is_found(tmp_path, photo, holds_file, monkeypatch, capsys):
    class Noise:
        def __call__(self, image, focal_px=None):
            return np.random.default_rng(0).uniform(1, 9, image.shape[:2]).astype(np.float32), FOCAL

    monkeypatch.setattr(runtime, "get_depth_estimator", lambda: Noise())
    out = tmp_path / "out.json"
    assert worker("ghost-wall", "--image", photo, "--holds", holds_file, "--out", out) == 1 and not out.exists()


# --- ghost-beta ----------------------------------------------------------------------------


@pytest.fixture
def beta(tmp_path, holds_wall):
    out = tmp_path / "beta.json"
    assert worker("ghost-beta", "--input", holds_wall, "--out", out) == 0
    return out


def test_ghost_beta_writes_the_steps_with_the_hold_ids_and_the_moved_limb(beta):
    data = load(beta)
    assert data["height_cm"] == 175 and data["preference"] == "easy"
    steps = data["steps"]
    assert len(steps) >= 4 and steps[0]["moved"] is None and all(s["moved"] for s in steps[1:])
    assert steps[0]["holds"]["left_hand"] == steps[0]["holds"]["right_hand"] == "0"  # start mark on hold 0
    assert steps[-1]["holds"]["left_hand"] == steps[-1]["holds"]["right_hand"] == "11"  # finish mark on hold 11
    assert set(steps[0]["holds"]) == {"left_hand", "right_hand", "left_foot", "right_foot"}


def test_ghost_beta_reads_the_morphology_file_and_the_options(tmp_path, holds_wall):
    morphology = tmp_path / "m.json"
    morphology.write_text(json.dumps({"height_cm": 160, "arm_span_cm": 158, "constraints": [{"type": "missing", "zone": "left_foot"}]}))
    out = tmp_path / "beta.json"
    assert worker("ghost-beta", "--input", holds_wall, "--out", out, "--morphology", morphology, "--preference", "power") == 0
    data = load(out)
    assert data["height_cm"] == 160 and data["preference"] == "power"
    assert all(s["holds"]["left_foot"] is None for s in data["steps"])  # a missing foot is never used


def test_ghost_beta_height_and_arm_span_options(tmp_path, holds_wall):
    out = tmp_path / "beta.json"
    assert worker("ghost-beta", "--input", holds_wall, "--out", out, "--height", 190, "--arm-span", 195) == 0
    assert load(out)["height_cm"] == 190


def test_ghost_beta_selected_holds_are_the_route(tmp_path, holds_wall):
    out = tmp_path / "beta.json"
    assert worker("ghost-beta", "--input", holds_wall, "--out", out, "--selected", "0,2,4,6,8,10") == 0
    used = {h for s in load(out)["steps"] for h in s["holds"].values() if h}
    assert used <= {"0", "2", "4", "6", "8", "10", "11"}  # the marked holds 0 and 11 are on the route too


def test_ghost_beta_feet_free_lets_the_feet_use_the_other_holds(tmp_path, holds_wall):
    out = tmp_path / "beta.json"
    assert worker("ghost-beta", "--input", holds_wall, "--out", out, "--selected", "0,2,4,6,8,10", "--feet-free") == 0
    steps = load(out)["steps"]
    route = {"0", "2", "4", "6", "8", "10", "11"}
    hands = {h for s in steps for k, h in s["holds"].items() if h and k.endswith("hand")}
    feet = {h for s in steps for k, h in s["holds"].items() if h and k.endswith("foot")}
    assert hands <= route and feet - route  # the hands stay on the route, the feet also use the other holds


def test_ghost_beta_without_a_wall_asks_for_ghost_wall_first(tmp_path, holds_file):
    out = tmp_path / "beta.json"
    assert worker("ghost-beta", "--input", holds_file, "--out", out) == 1 and not out.exists()


def test_ghost_beta_reports_the_missing_passage(tmp_path, photo, caplog):
    far = holds_json()
    far["holds"] = [far["holds"][0], {**far["holds"][11], "contour": {**far["holds"][11]["contour"]}}]
    for p in far["holds"][1]["contour"]["points"]:
        p["y"] -= 600  # 450 cm above: nobody reaches it
    holds = tmp_path / "far.json"
    holds.write_text(json.dumps(far))
    wall = tmp_path / "far_wall.json"
    assert worker("ghost-wall", "--image", photo, "--holds", holds, "--out", wall) == 0
    assert worker("ghost-beta", "--input", wall, "--out", tmp_path / "beta.json") == 1
    assert "no beta" in caplog.text and "cannot get from 0 to 1" in caplog.text  # the holds around the gap
    assert not (tmp_path / "beta.json").exists()


# --- ghost-pose and ghost ------------------------------------------------------------------


@pytest.fixture
def path_json(tmp_path, beta, holds_wall):
    out = tmp_path / "path.json"
    assert worker("ghost-pose", "--input", beta, "--holds", holds_wall, "--out", out) == 0
    return out


def test_ghost_pose_writes_a_valid_ghost_path(path_json):
    path = GhostPath.model_validate_json(path_json.read_text())
    assert (path.image_width, path.image_height) == (WIDTH, HEIGHT) and len(path.steps) >= 4
    assert all(len(s.landmarks) == 33 for s in path.steps)


def test_ghost_pose_renders_on_the_photo(tmp_path, beta, holds_wall, photo):
    render = tmp_path / "render.png"
    assert worker("ghost-pose", "--input", beta, "--holds", holds_wall, "--out", tmp_path / "p.json", "--render", render, "--image", photo) == 0
    image = cv2.imread(str(render))
    assert image.shape == (HEIGHT, WIDTH, 3) and (image != 140).any()


def test_ghost_pose_render_needs_the_photo(tmp_path, beta, holds_wall):
    assert worker("ghost-pose", "--input", beta, "--holds", holds_wall, "--out", tmp_path / "p.json", "--render", tmp_path / "r.png") == 1


def test_ghost_pose_rejects_a_beta_that_is_not_for_these_holds(tmp_path, holds_wall):
    bad = tmp_path / "beta.json"
    bad.write_text(json.dumps({"height_cm": 175, "steps": [{"holds": {"left_hand": "99", "right_hand": None, "left_foot": None, "right_foot": None}, "moved": None}]}))
    assert worker("ghost-pose", "--input", bad, "--holds", holds_wall, "--out", tmp_path / "p.json") == 1


def test_the_three_steps_chained_give_the_result_of_ghost(tmp_path, photo, holds_file, path_json):
    out = tmp_path / "ghost.json"
    render = tmp_path / "ghost.png"
    assert worker("ghost", "--image", photo, "--holds", holds_file, "--out", out, "--render", render) == 0
    assert GhostPath.model_validate_json(out.read_text()) == GhostPath.model_validate_json(path_json.read_text())
    assert cv2.imread(str(render)).shape == (HEIGHT, WIDTH, 3)


def test_ghost_without_holds_detects_them(tmp_path, photo):
    out = tmp_path / "ghost.json"
    assert worker("ghost", "--image", photo, "--out", out) == 0
    assert len(GhostPath.model_validate_json(out.read_text()).steps) >= 4


def test_ghost_options_reach_the_search(tmp_path, photo, holds_file):
    easy, power = tmp_path / "easy.json", tmp_path / "power.json"
    assert worker("ghost", "--image", photo, "--holds", holds_file, "--out", easy) == 0
    assert worker("ghost", "--image", photo, "--holds", holds_file, "--out", power, "--preference", "power", "--height", 190, "--arm-span", 195) == 0
    assert GhostPath.model_validate_json(easy.read_text()) != GhostPath.model_validate_json(power.read_text())


@pytest.mark.parametrize("command", ["ghost-wall", "ghost-beta", "ghost-pose", "ghost"])
def test_every_ghost_command_has_help(command, capsys):
    with pytest.raises(SystemExit) as exit_:
        cli.main([command, "--help"])
    assert exit_.value.code == 0 and "--out" in capsys.readouterr().out


@pytest.mark.parametrize("command", [["ghost-beta", "--input"], ["ghost-pose", "--holds", "x", "--input"]])
def test_missing_or_garbage_input_gives_a_non_zero_code(tmp_path, command):
    garbage = tmp_path / "garbage.json"
    garbage.write_text("{not json")
    out = tmp_path / "out.json"
    for target in (tmp_path / "missing.json", garbage):
        argv = [*command, str(target), "--out", str(out)]
        assert worker(*argv) == 1 and not out.exists()


# --- --color: the route is the holds of one colour -----------------------------------------

YELLOW = [0, 2, 4, 6, 8, 10, 11]


@pytest.fixture
def coloured_wall(tmp_path, photo):
    """The ladder with its even holds (and the last one) yellow, the others blue, with the wall."""
    marks = {i: {"color": {"name": "yellow" if i in YELLOW else "blue", "rgb": [250, 220, 20], "distance": 5.0}} for i in range(12)}
    marks[0]["start_limbs"], marks[11]["finish_limbs"] = 2, 2
    holds = tmp_path / "coloured.json"
    holds.write_text(json.dumps(holds_json(marks)))
    out = tmp_path / "coloured_wall.json"
    assert worker("ghost-wall", "--image", photo, "--holds", holds, "--out", out) == 0
    return out, holds


def test_ghost_beta_color_keeps_only_the_holds_of_that_colour(tmp_path, coloured_wall):
    out = tmp_path / "beta.json"
    assert worker("ghost-beta", "--input", coloured_wall[0], "--out", out, "--color", "yellow") == 0
    used = {h for s in load(out)["steps"] for h in s["holds"].values() if h}
    assert used and used <= {str(i) for i in YELLOW}


def test_ghost_beta_color_adds_to_selected(tmp_path, coloured_wall):
    out = tmp_path / "beta.json"
    assert worker("ghost-beta", "--input", coloured_wall[0], "--out", out, "--color", "yellow", "--selected", "1,3") == 0
    used = {h for s in load(out)["steps"] for h in s["holds"].values() if h}
    assert used <= {str(i) for i in YELLOW} | {"1", "3"}


def test_ghost_beta_color_is_case_insensitive(tmp_path, coloured_wall):
    lower, upper = tmp_path / "lower.json", tmp_path / "upper.json"
    assert worker("ghost-beta", "--input", coloured_wall[0], "--out", lower, "--color", "yellow") == 0
    assert worker("ghost-beta", "--input", coloured_wall[0], "--out", upper, "--color", "Yellow") == 0
    assert load(lower) == load(upper)


def test_ghost_beta_unknown_color_fails_and_lists_the_colours(tmp_path, coloured_wall, caplog):
    out = tmp_path / "beta.json"
    assert worker("ghost-beta", "--input", coloured_wall[0], "--out", out, "--color", "pink") == 1
    assert not out.exists() and "pink" in caplog.text and "yellow" in caplog.text and "blue" in caplog.text


def test_ghost_color_gives_the_ghost_of_those_holds(tmp_path, photo, coloured_wall):
    by_color, by_ids = tmp_path / "color.json", tmp_path / "ids.json"
    assert worker("ghost", "--image", photo, "--holds", coloured_wall[1], "--out", by_color, "--color", "yellow") == 0
    assert worker("ghost", "--image", photo, "--holds", coloured_wall[1], "--out", by_ids, "--selected", ",".join(map(str, YELLOW))) == 0
    assert GhostPath.model_validate_json(by_color.read_text()) == GhostPath.model_validate_json(by_ids.read_text())
