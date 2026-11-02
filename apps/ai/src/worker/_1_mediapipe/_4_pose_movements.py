# @date 2026-11-02
# @file _4_pose_movements.py
# @brief File description.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""Step A4: split the time series into limb movements and pauses (speed rules only)."""

#: Limb name -> joint whose speed (computed by `_3_pose_metrics`) drives it.
LIMB_JOINTS = {
    "left_hand": "left_wrist",
    "right_hand": "right_wrist",
    "left_foot": "left_ankle",
    "right_foot": "right_ankle",
}
#: A movement starts when the speed (torso lengths per second) reaches this.
MOVE_SPEED_THRESHOLD = 0.8
#: ... and stops when it falls below this (lower than the start threshold: hysteresis).
STOP_SPEED_THRESHOLD = 0.4
#: Two movements of the same limb closer than this are merged.
MERGE_GAP_MS = 150
#: Movements shorter than this are dropped.
MIN_MOVE_MS = 100
#: A pause is a stretch with no moving limb of at least this duration.
MIN_PAUSE_MS = 500


def _runs(speeds: list[float | None], move: float, stop: float) -> list[list[int]]:
    """Hysteresis on one limb: ``[first, last]`` frame positions of each run."""
    runs: list[list[int]] = []
    moving = False
    for i, v in enumerate(speeds):
        # A missing speed (lost pose) closes the run; so does a speed below `stop`.
        if v is None or v < (stop if moving else move):
            moving = False
        elif moving:
            runs[-1][1] = i
        else:
            moving = True
            runs.append([i, i])
    return runs


def _merge_and_filter(runs, speeds, frame_ms, merge_gap_ms, min_move_ms):
    merged: list[list[int]] = []
    for run in runs:
        gap = range(merged[-1][1] + 1, run[0]) if merged else None
        # Never bridge a stretch where the speed is unknown.
        if merged and len(gap) * frame_ms < merge_gap_ms and all(speeds[k] is not None for k in gap):
            merged[-1][1] = run[1]
        else:
            merged.append(run)
    return [r for r in merged if (r[1] - r[0] + 1) * frame_ms >= min_move_ms]


def detect_movements(
    result: dict,
    move_speed: float = MOVE_SPEED_THRESHOLD,
    stop_speed: float = STOP_SPEED_THRESHOLD,
    merge_gap_ms: float = MERGE_GAP_MS,
    min_move_ms: float = MIN_MOVE_MS,
    min_pause_ms: float = MIN_PAUSE_MS,
) -> dict:
    """Return a copy of an `AnalysisResult`-shaped dict with ``movements`` and ``pauses``.

    Reads the per-frame ``speeds`` from `_3_pose_metrics`. Each limb gets its own hysteresis
    (start at ``move_speed``, stop below ``stop_speed``), then close movements are merged
    and short ones dropped. A frame with no speed for a limb ends that limb's movement.

    A pause is a stretch of at least ``min_pause_ms`` where every limb is measured and
    none moves. A frame where any limb speed is unknown (lost pose or low visibility)
    ends the pause and never counts toward one: nothing says that limb is still.
    """
    frames, fps = result["frames"], result["fps"]
    frame_ms = 1000 / fps
    movements = []
    in_motion = [False] * len(frames)
    for limb, joint in LIMB_JOINTS.items():
        speeds = [f.get("speeds", {}).get(joint) for f in frames]
        runs = _runs(speeds, move_speed, stop_speed)
        for a, b in _merge_and_filter(runs, speeds, frame_ms, merge_gap_ms, min_move_ms):
            movements.append(_interval(frames, a, b, limb=limb))
            for k in range(a, b + 1):
                in_motion[k] = True

    pauses = []
    start = None
    for i, f in enumerate(frames + [None]):  # sentinel closes the last stretch
        still = f is not None and not in_motion[i] and all(j in f.get("speeds", {}) for j in LIMB_JOINTS.values())
        if still and start is None:
            start = i
        elif not still and start is not None:
            if (i - start) * frame_ms >= min_pause_ms:
                pauses.append(_interval(frames, start, i - 1))
            start = None

    movements.sort(key=lambda m: (m["start_frame"], m["limb"]))
    return {**result, "movements": movements, "pauses": pauses}


def _interval(frames: list[dict], a: int, b: int, **extra) -> dict:
    return {
        **extra,
        "start_frame": frames[a]["frame"],
        "end_frame": frames[b]["frame"],
        "start_ms": frames[a]["timestamp_ms"],
        "end_ms": frames[b]["timestamp_ms"],
    }
