# @date 2026-11-24
# @file test_cli_holds.py
# @brief Runs the hold sub-commands of `worker` as real processes with the bundled ONNX model.
# @project Ascension
# @author Livoooo <zarigu92@gmail.com>
# @copyright (c) 2026 Ascension
# @status done
import json

import cv2
import numpy as np
import pytest

from shared.models import HoldDetectResult
from tests.functional.test_cli import APP, run

pytestmark = [
    pytest.mark.functional,
    pytest.mark.skipif(not (APP / "resources" / "holds_seg.onnx").is_file(), reason="resources/holds_seg.onnx is missing"),
]


def test_holds_detect_writes_a_valid_result_and_a_render(tmp_path):
    photo = tmp_path / "wall.jpg"
    wall = np.full((480, 640, 3), 150, np.uint8)
    cv2.circle(wall, (320, 240), 40, (40, 40, 200), -1)  # one red blob on a grey wall
    cv2.imwrite(str(photo), wall)
    out, render = tmp_path / "holds.json", tmp_path / "render.jpg"
    r = run("holds-detect", "--image", photo, "--out", out, "--render", render)
    assert r.returncode == 0, r.stderr
    result = HoldDetectResult.model_validate_json(out.read_text())
    assert (result.image_width, result.image_height) == (640, 480)
    assert cv2.imread(str(render)).shape == (480, 640, 3)


def test_holds_detect_rejects_a_file_that_is_not_an_image(tmp_path):
    bad = tmp_path / "wall.jpg"
    bad.write_text("not an image")
    r = run("holds-detect", "--image", bad, "--out", tmp_path / "out.json")
    assert r.returncode == 1
    assert "unreadable" in r.stdout + r.stderr  # the logger may wrap the rest of the message


def test_holds_colors_eval_scores_a_labelled_dataset(tmp_path):
    (tmp_path / "images" / "val").mkdir(parents=True)
    (tmp_path / "labels" / "val").mkdir(parents=True)
    wall = np.full((200, 200, 3), 150, np.uint8)
    wall[50:150, 50:150] = (200, 60, 20)  # blue square
    cv2.imwrite(str(tmp_path / "images" / "val" / "a.jpg"), wall)
    (tmp_path / "labels" / "val" / "a.txt").write_text("0 0.25 0.25 0.75 0.25 0.75 0.75 0.25 0.75\n")
    (tmp_path / "meta.json").write_text(json.dumps({"val/a.jpg": {"instances": ["blue_hold"]}}))
    r = run("holds-colors-eval", "--dataset", tmp_path)
    assert r.returncode == 0, r.stderr
    assert "accuracy 1.000 on 1 holds" in r.stdout
