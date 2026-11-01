# @date 2026-11-01
# @file test_pose_movements.py
# @brief File description.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
from worker._1_mediapipe.pose_movements import detect_movements

FPS = 100.0  # 10 ms per frame
LIMBS = ("left_wrist", "right_wrist", "left_ankle", "right_ankle")


def series(**joints):
    """Build a result from per-joint speed lists; ``None`` = unknown speed. Unlisted joints stay still (0)."""
    n = len(next(iter(joints.values())))
    frames = []
    for i in range(n):
        speeds = {j: joints.get(j, [0.0] * n)[i] for j in LIMBS}
        frames.append(
            {
                "frame": i,
                "timestamp_ms": i * 10,
                "pose_detected": True,
                "landmarks": {},
                "angles": {},
                "speeds": {j: v for j, v in speeds.items() if v is not None},
            }
        )
    return {"fps": FPS, "width": 100, "height": 100, "frames": frames}


def run(**kw):
    speeds = {k: kw.pop(k) for k in list(kw) if k in LIMBS}
    return detect_movements(series(**speeds), **kw)


def span(m):
    return (m["limb"], m["start_frame"], m["end_frame"], m["start_ms"], m["end_ms"])


def test_two_peaks_give_two_movements():
    w = [0] * 5 + [2] * 20 + [0] * 30 + [2] * 20 + [0] * 5
    out = run(left_wrist=w)
    assert [span(m) for m in out["movements"]] == [
        ("left_hand", 5, 24, 50, 240),
        ("left_hand", 55, 74, 550, 740),
    ]


def test_noise_around_threshold_is_one_movement():
    # Dips between stop (0.4) and move (0.8) must not split the movement.
    w = [0] * 5 + [1.0, 0.6, 0.9, 0.5, 1.0, 0.6, 0.9] * 4 + [0] * 5
    assert len(run(left_wrist=w)["movements"]) == 1


def test_close_movements_merge_and_isolated_short_peak_is_dropped():
    close = [0] * 5 + [2] * 20 + [0] * 10 + [2] * 20 + [0] * 5  # 100 ms gap: merged
    far = [0] * 5 + [2] * 20 + [0] * 20 + [2] * 20 + [0] * 5  # 200 ms gap: kept apart
    assert [span(m)[1:3] for m in run(left_wrist=close)["movements"]] == [(5, 54)]
    assert len(run(left_wrist=far)["movements"]) == 2
    blip = [0] * 20 + [2] * 5 + [0] * 20  # 50 ms < MIN_MOVE_MS
    assert run(left_wrist=blip)["movements"] == []


def test_pause_only_when_all_limbs_are_still():
    n = 80
    still = run(left_wrist=[0.0] * n)
    assert [(p["start_frame"], p["end_frame"]) for p in still["pauses"]] == [(0, n - 1)]
    # One foot moves in the middle: the stretches before and after are separate pauses.
    ankle = [0] * 60 + [2] * 20 + [0] * 60
    out = run(left_ankle=ankle)
    assert [(p["start_frame"], p["end_frame"]) for p in out["pauses"]] == [(0, 59), (80, 139)]
    # A pause shorter than 500 ms is not reported.
    assert run(left_wrist=[0.0] * 40)["pauses"] == []


def test_lost_pose_makes_no_pause_and_no_movement():
    n = 80
    lost = run(left_wrist=[None] * n)  # one limb never measured: nothing is known to be still
    assert lost["pauses"] == [] and lost["movements"] == []
    # Lost speed closes a movement and is neither bridged nor counted as still.
    w = [0] * 5 + [2] * 10 + [None] * 3 + [2] * 10 + [0] * 5
    out = run(left_wrist=w)
    assert [span(m)[1:3] for m in out["movements"]] == [(5, 14), (18, 27)]
    assert out["pauses"] == []
