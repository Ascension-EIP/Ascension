# @date 2026-11-02
# @file test_pose.py
# @brief File description.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
from pathlib import Path

import cv2
import pytest

from common.utils.errors import PermanentError
from worker._1_mediapipe._1_pose_skeleton import PoseSkeleton, resolve_model_path
from worker._1_mediapipe._2_pose_filter import filter_frames
from worker._1_mediapipe._3_pose_metrics import compute_metrics
from worker._1_mediapipe.pose_geometry import frame_angles

AI_ROOT = Path(__file__).resolve().parents[1]
VIDEO = AI_ROOT / "resources" / "example-2.mp4"
needs_assets = pytest.mark.skipif(
    not (VIDEO.exists() and Path(resolve_model_path()).exists()), reason="model or example video missing"
)


def lm(x, y, visibility=1.0):
    return {"x": x, "y": y, "z": 0.0, "visibility": visibility}


def result(frames, width=1080, height=1920, fps=30.0):
    return {
        "fps": fps,
        "width": width,
        "height": height,
        "frames": [
            {"frame": i, "timestamp_ms": int(i / fps * 1000), "pose_detected": bool(f), "landmarks": f, "angles": {}}
            for i, f in enumerate(frames)
        ],
    }


def test_angle_is_computed_in_pixels():
    # Vectors (100, 100) px and (100, -100) px from the vertex are perpendicular in pixels,
    # but not in normalized coordinates on a 1080x1920 image.
    w, h = 1080, 1920
    pts = {
        "left_shoulder": lm(0.5 + 100 / w, 0.5 + 100 / h),
        "left_elbow": lm(0.5, 0.5),
        "left_wrist": lm(0.5 + 100 / w, 0.5 - 100 / h),
    }
    assert frame_angles(pts, w, h)["left_elbow"] == 90.0
    assert frame_angles(pts, 1, 1)["left_elbow"] != 90.0  # what normalized maths would give


def test_short_gap_filled_long_gap_left_and_angle_omitted():
    def arm(wrist_visible):
        return {
            "left_shoulder": lm(0.5, 0.2),
            "left_elbow": lm(0.5, 0.4),
            "left_wrist": lm(0.6, 0.4, 1.0 if wrist_visible else 0.1),
        }

    visible = [True] * 3 + [False] * 3 + [True] * 3 + [False] * 8 + [True] * 3
    out = filter_frames(result([arm(v) for v in visible]), window=1)["frames"]
    for i in (3, 4, 5):  # 3 missing frames <= MAX_GAP_FRAMES: filled
        assert "left_wrist" in out[i]["landmarks"] and "left_elbow" in out[i]["angles"]
    for i in range(9, 17):  # 8 missing frames: left empty, angle omitted
        assert "left_wrist" not in out[i]["landmarks"] and "left_elbow" not in out[i]["angles"]
    assert out[0]["angles"]["left_elbow"] == out[3]["angles"]["left_elbow"]


def test_smoothing_averages_neighbours():
    frames = [{"left_wrist": lm(x, 0.5)} for x in (0.0, 0.0, 0.3, 0.0, 0.0)]
    mid = filter_frames(result(frames), window=3)["frames"][2]["landmarks"]["left_wrist"]
    assert mid["x"] == pytest.approx(0.1)


def arm_frame(wrist):
    return {"left_shoulder": lm(0.5, 0.2), "left_elbow": lm(0.5, 0.4), "left_wrist": lm(*wrist)}


def test_arm_extension_straight_vs_bent():
    out = compute_metrics(result([arm_frame((0.5, 0.6)), arm_frame((0.7, 0.4))]))
    straight, bent = (f["arm_extension"]["left"] for f in out["frames"])
    assert straight == pytest.approx(1.0)
    assert bent < 0.8
    assert out["metrics"]["bent_arm_ratio"] == {"left": 0.5}
    assert "right" not in out["frames"][0]["arm_extension"]


def test_metrics_without_torso_do_not_crash():
    out = compute_metrics(result([arm_frame((0.5, 0.6)), arm_frame((0.5, 0.6))]))
    assert "speeds" not in out["frames"][1]
    assert "avg_speed" not in out["metrics"]
    assert out["metrics"]["pose_detection_rate"] == 1.0


def test_speed_in_torso_lengths_per_second():
    def f(wrist_x):
        return {
            "left_shoulder": lm(0.4, 0.2),
            "right_shoulder": lm(0.6, 0.2),
            "left_hip": lm(0.4, 0.4),
            "right_hip": lm(0.6, 0.4),
            "left_wrist": lm(wrist_x, 0.5),
        }

    # Torso = 0.2 * 1920 = 384 px. The wrist moves 0.1 * 1080 = 108 px in 1/30 s.
    speed = compute_metrics(result([f(0.5), f(0.6)]))["frames"][1]["speeds"]["left_wrist"]
    assert speed == pytest.approx(108 / 384 * 30, rel=1e-3)


@pytest.mark.parametrize("content", [b"not a video at all", None])
def test_unreadable_video_is_permanent(tmp_path, content):
    path = tmp_path / "bad.mp4"
    if content:
        path.write_bytes(content)
    with pytest.raises(PermanentError):
        PoseSkeleton(model="unused").process(str(path))


@needs_assets
def test_two_videos_in_a_row_and_progress(tmp_path):
    clip = tmp_path / "clip.mp4"
    cap = cv2.VideoCapture(str(VIDEO))
    writer = None
    for _ in range(15):
        ok, frame = cap.read()
        assert ok
        writer = writer or cv2.VideoWriter(str(clip), cv2.VideoWriter_fourcc(*"mp4v"), 30, frame.shape[1::-1])
        writer.write(frame)
    writer.release()
    cap.release()

    skeleton = PoseSkeleton()  # same instance for both videos
    for _ in range(2):
        percents: list[int] = []
        frames = skeleton.process(str(clip), on_progress=percents.append).result["frames"]
        assert len(frames) > 0
        assert percents == sorted(set(percents)) and percents[-1] == 100
