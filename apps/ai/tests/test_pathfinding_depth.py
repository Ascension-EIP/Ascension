# @date 2026-11-25
# @file test_pathfinding_depth.py
# @brief Tests of the metric depth estimator (pathfinding step C1) with a fake ONNX session, and of its CLI commands.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
import json
import math

import cv2
import numpy as np
import pytest

from worker import cli, runtime
from worker._4_pathfinding import _1_depth as depth_mod

# Synthetic camera: a plane 3 m away, seen with a 600 px focal on a 160x120 image.
TRUE_FOCAL_PX, PLANE_M = 600.0, 3.0
METRIC_SCALE, SHIFT = 2.0, 0.5  # the model outputs affine points: metric = scale * (z + shift)


def moge_outputs(width: int, height: int, mask: float = 1.0, focal_px: float = TRUE_FOCAL_PX) -> list[np.ndarray]:
    """What the MoGe-2 ONNX returns (points, normal, mask, scale) for a tilted plane seen by a pinhole camera."""
    u, v = np.meshgrid(np.arange(width) - (width - 1) / 2, np.arange(height) - (height - 1) / 2)
    z = PLANE_M + 0.002 * u  # plane turned around the vertical axis: depth varies along x
    x, y = u / focal_px * z, v / focal_px * z
    points = np.stack([x / METRIC_SCALE, y / METRIC_SCALE, z / METRIC_SCALE - SHIFT], axis=-1)
    return [
        points[None].astype(np.float32),
        np.zeros((1, height, width, 3), np.float32),
        np.full((1, height, width), mask, np.float32),
        np.array([METRIC_SCALE], np.float32),
    ]


class FakeSession:
    """Stands for `onnxruntime.InferenceSession`: records its inputs, answers with a synthetic scene."""

    def __init__(self, **kwargs):
        self.kwargs = kwargs
        self.calls: list[dict] = []

    def run(self, _outputs, feed):
        self.calls.append(feed)
        _, _, height, width = feed["image"].shape
        return moge_outputs(width, height, **self.kwargs)


@pytest.fixture
def model_file(tmp_path):
    path = tmp_path / "depth.onnx"
    path.write_bytes(b"not a real model")
    return path


def estimator(monkeypatch, model_file, **kwargs) -> depth_mod.DepthEstimator:
    session = FakeSession(**kwargs)
    monkeypatch.setattr(depth_mod.ort, "InferenceSession", lambda *a, **k: session)
    return depth_mod.DepthEstimator(model_file)


def photo(width: int = 160, height: int = 120) -> np.ndarray:
    return np.full((height, width, 3), 128, np.uint8)


def test_missing_model_file_raises_file_not_found(tmp_path):
    with pytest.raises(FileNotFoundError, match="depth model not found"):
        depth_mod.DepthEstimator(tmp_path / "nope.onnx")


def test_depth_model_path_defaults_to_the_resources_folder(monkeypatch):
    monkeypatch.delenv("DEPTH_MODEL_PATH", raising=False)
    path = depth_mod.depth_model_path()
    assert path == str(depth_mod.AI_ROOT / "resources" / "moge-2-vits-normal.onnx")


def test_depth_model_path_reads_the_environment(monkeypatch):
    monkeypatch.setenv("DEPTH_MODEL_PATH", "resources/other.onnx")
    assert depth_mod.depth_model_path() == str(depth_mod.AI_ROOT / "resources" / "other.onnx")


def test_depth_is_metric_and_focal_is_recovered_from_the_points(monkeypatch, model_file):
    depth, focal = estimator(monkeypatch, model_file)(photo())
    assert depth.shape == (120, 160) and depth.dtype == np.float32
    assert focal == pytest.approx(TRUE_FOCAL_PX, rel=0.02)
    centre = depth[60, 80]
    assert centre == pytest.approx(PLANE_M, rel=0.01)
    assert depth[60, 150] > depth[60, 10]  # the plane is slanted: depth grows with x


def test_a_known_focal_is_used_instead_of_the_estimated_one(monkeypatch, model_file):
    _, focal = estimator(monkeypatch, model_file)(photo(), focal_px=TRUE_FOCAL_PX)
    assert focal == TRUE_FOCAL_PX


def test_large_images_are_shrunk_for_the_model_and_the_depth_comes_back_at_full_size(monkeypatch, model_file):
    est = estimator(monkeypatch, model_file)
    big = photo(1280, 960)
    depth, focal = est(big)
    fed = est.session.calls[0]["image"]
    assert max(fed.shape[2:]) == depth_mod.MAX_SIDE
    assert depth.shape == (960, 1280)
    assert focal == pytest.approx(TRUE_FOCAL_PX * 2, rel=0.02)  # the fake sees 640 px at 600 px focal; the photo is twice as wide


def test_image_is_fed_as_rgb_floats_with_the_token_budget(monkeypatch, model_file):
    est = estimator(monkeypatch, model_file)
    bgr = np.zeros((120, 160, 3), np.uint8)
    bgr[..., 0] = 255  # pure blue in BGR
    est(bgr)
    feed = est.session.calls[0]
    assert feed["image"].dtype == np.float32 and feed["image"].shape == (1, 3, 120, 160)
    assert feed["image"][0, 2].min() == 1.0 and feed["image"][0, 0].max() == 0.0  # blue ends up in channel 2
    assert feed["num_tokens"] == depth_mod.NUM_TOKENS and feed["num_tokens"].dtype == np.int64


def test_pixels_outside_the_model_mask_are_nan(monkeypatch, model_file):
    depth, _ = estimator(monkeypatch, model_file)(photo())
    fully_masked, _ = estimator(monkeypatch, model_file, mask=0.0)(photo())
    assert np.isfinite(depth).all()
    assert np.isnan(fully_masked).all()


def test_without_a_usable_fit_the_default_field_of_view_gives_the_focal(monkeypatch, model_file):
    _, focal = estimator(monkeypatch, model_file, mask=0.0)(photo(160, 120))
    assert focal == pytest.approx(80 / math.tan(math.radians(depth_mod.DEFAULT_HFOV_DEG / 2)))


def test_get_depth_estimator_raises_file_not_found_when_the_path_points_nowhere(monkeypatch, tmp_path):
    monkeypatch.setenv("DEPTH_MODEL_PATH", str(tmp_path / "missing.onnx"))
    runtime.get_depth_estimator.cache_clear()
    try:
        with pytest.raises(FileNotFoundError, match="depth model not found"):
            runtime.get_depth_estimator()
    finally:
        runtime.get_depth_estimator.cache_clear()


def test_get_depth_estimator_is_cached(monkeypatch, model_file):
    monkeypatch.setattr(depth_mod.ort, "InferenceSession", lambda *a, **k: FakeSession())
    monkeypatch.setenv("DEPTH_MODEL_PATH", str(model_file))
    runtime.get_depth_estimator.cache_clear()
    try:
        assert runtime.get_depth_estimator() is runtime.get_depth_estimator()
    finally:
        runtime.get_depth_estimator.cache_clear()


# --- render and evaluation ---------------------------------------------------------------------


def test_render_depth_colours_near_and_far_differently_and_greys_out_invalid_pixels():
    depth = np.array([[1.0, 2.0, np.nan], [3.0, 4.0, 5.0]], np.float32)
    image = depth_mod.render_depth(depth)
    assert image.shape == (2, 3, 3) and image.dtype == np.uint8
    assert not np.array_equal(image[0, 0], image[1, 2])
    assert (image[0, 2] == 0).all()  # invalid pixel: black


def fake_estimator(depth_m: float = PLANE_M, focal_px: float = TRUE_FOCAL_PX):
    """Estimator of a flat wall `depth_m` away, as a callable like `DepthEstimator`."""

    def estimate(image, focal=None):
        return np.full(image.shape[:2], depth_m, np.float32), focal_px

    return estimate


def dataset(tmp_path, distance_cm: float, pairs_per_image: int = 1) -> None:
    """One 200x100 image with pairs of pixels 100 px apart: 100 px at 3 m and 600 px focal is 50 cm."""
    cv2.imwrite(str(tmp_path / "a.jpg"), photo(200, 100))
    pairs = [{"a": [50, 50], "b": [150, 50], "distance_cm": distance_cm} for _ in range(pairs_per_image)]
    (tmp_path / "annotations.json").write_text(json.dumps([{"image": "a.jpg", "pairs": pairs}]))


def test_evaluate_depth_measures_the_relative_error_of_the_3d_distance(tmp_path):
    dataset(tmp_path, distance_cm=40.0)  # the estimate is 50 cm: 25 % too long
    report = depth_mod.evaluate_depth(tmp_path, fake_estimator())
    assert report["pairs"] == 1 and report["skipped"] == 0
    assert report["mean"] == pytest.approx(0.25) and report["median"] == pytest.approx(0.25)
    (image,) = report["images"]
    assert image["image"] == "a.jpg" and image["errors"] == [pytest.approx(0.25)]
    assert image["focal_px"] == TRUE_FOCAL_PX


def test_evaluate_depth_is_exact_when_the_scale_is_right(tmp_path):
    dataset(tmp_path, distance_cm=50.0)
    report = depth_mod.evaluate_depth(tmp_path, fake_estimator())
    assert report["mean"] == pytest.approx(0.0, abs=1e-6)


def test_evaluate_depth_skips_pairs_on_invalid_pixels_and_counts_them(tmp_path):
    dataset(tmp_path, distance_cm=50.0)
    report = depth_mod.evaluate_depth(tmp_path, fake_estimator(depth_m=float("nan")))
    assert report["pairs"] == 0 and report["skipped"] == 1
    assert math.isnan(report["mean"])


def test_evaluate_depth_mean_and_median_differ_on_skewed_errors(tmp_path):
    cv2.imwrite(str(tmp_path / "a.jpg"), photo(200, 100))
    pairs = [{"a": [50, 50], "b": [150, 50], "distance_cm": d} for d in (50.0, 50.0, 25.0)]  # errors 0, 0, 1
    (tmp_path / "annotations.json").write_text(json.dumps([{"image": "a.jpg", "pairs": pairs}]))
    report = depth_mod.evaluate_depth(tmp_path, fake_estimator())
    assert report["median"] == pytest.approx(0.0, abs=1e-6)
    assert report["mean"] == pytest.approx(1 / 3)


# --- command line ------------------------------------------------------------------------------


@pytest.fixture
def fake_runtime(monkeypatch):
    monkeypatch.setattr(runtime, "get_depth_estimator", lambda: fake_estimator())


def test_depth_eval_command_prints_the_errors(tmp_path, fake_runtime, capsys):
    dataset(tmp_path, distance_cm=40.0)
    cli.main(["depth-eval", "--dataset", str(tmp_path)])
    out = capsys.readouterr().out
    assert "a.jpg" in out and "mean 25.0%" in out and "median 25.0%" in out
    assert "all: 1 pairs" in out


def test_depth_eval_command_fails_cleanly_without_annotations(tmp_path, fake_runtime):
    with pytest.raises(SystemExit) as exit_info:
        cli.main(["depth-eval", "--dataset", str(tmp_path)])
    assert exit_info.value.code == 1


def test_pathfinding_depth_command_writes_the_depth_in_metres_and_prints_the_focal(tmp_path, fake_runtime, capsys):
    cv2.imwrite(str(tmp_path / "wall.jpg"), photo(160, 120))
    out, render = tmp_path / "depth.npy", tmp_path / "depth.png"
    cli.main(["pathfinding-depth", "--image", str(tmp_path / "wall.jpg"), "--out", str(out), "--render", str(render)])
    depth = np.load(out)
    assert depth.shape == (120, 160) and depth.dtype == np.float32 and depth[0, 0] == PLANE_M
    assert cv2.imread(str(render)).shape == (120, 160, 3)
    assert f"focal {TRUE_FOCAL_PX:.1f} px" in capsys.readouterr().out


def test_pathfinding_depth_command_without_render_writes_only_the_depth(tmp_path, fake_runtime):
    cv2.imwrite(str(tmp_path / "wall.jpg"), photo(160, 120))
    cli.main(["pathfinding-depth", "--image", str(tmp_path / "wall.jpg"), "--out", str(tmp_path / "depth.npy")])
    assert sorted(p.name for p in tmp_path.iterdir()) == ["depth.npy", "wall.jpg"]


def test_pathfinding_depth_command_rejects_a_file_that_is_not_an_image(tmp_path, fake_runtime):
    bad = tmp_path / "wall.jpg"
    bad.write_text("not an image")
    with pytest.raises(SystemExit) as exit_info:
        cli.main(["pathfinding-depth", "--image", str(bad), "--out", str(tmp_path / "depth.npy")])
    assert exit_info.value.code == 1
    assert not (tmp_path / "depth.npy").exists()


GYM_PHOTO = depth_mod.AI_ROOT.parents[1] / "docs/Ascension/resources/images/deck/climb_olivier.jpeg"


@pytest.mark.skipif(
    not (depth_mod.AI_ROOT / depth_mod.DEFAULT_MODEL_PATH).is_file() or not GYM_PHOTO.is_file(),
    reason="needs the downloaded model (`moon run ai:setup-depth`) and the gym photo of the docs",
)
def test_the_real_model_answers_with_a_finite_metric_depth():
    image = cv2.resize(cv2.imread(str(GYM_PHOTO)), (470, 568))
    depth, focal = depth_mod.DepthEstimator(depth_mod.depth_model_path())(image)
    assert depth.shape == (568, 470) and depth.dtype == np.float32
    assert np.isfinite(depth).mean() > 0.9 and 0.5 < np.nanmedian(depth) < 10  # an indoor scene, in metres
    assert 100 < focal < 20000
