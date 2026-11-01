# @date 2026-11-01
# @file pose_filter.py
# @brief File description.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""Step A2: drop unreliable landmarks, fill short gaps, smooth, recompute angles."""

from itertools import pairwise

import numpy as np

from worker._1_mediapipe.pose_geometry import frame_angles

#: A landmark below this visibility is treated as missing.
MIN_VISIBILITY = 0.5
#: Longest run of missing frames that is filled by interpolation.
MAX_GAP_FRAMES = 5
#: Width (frames) of the centered moving average.
SMOOTH_WINDOW = 5
COORD_PRECISION = 4


def _fill_gaps(values: np.ndarray, valid: np.ndarray, max_gap: int) -> tuple[np.ndarray, np.ndarray]:
    """Linearly interpolate runs of invalid samples of at most ``max_gap`` frames.

    Leading/trailing runs are never filled. Returns the new values and validity.
    """
    values, valid = values.copy(), valid.copy()
    idx = np.flatnonzero(valid)
    for left, right in pairwise(idx):
        if 1 < right - left <= max_gap + 1:
            t = np.arange(left + 1, right)
            values[t] = np.array(
                [np.interp(t, [left, right], [values[left, c], values[right, c]]) for c in range(values.shape[1])]
            ).T
            valid[t] = True
    return values, valid


def _smooth(values: np.ndarray, valid: np.ndarray, window: int) -> np.ndarray:
    """Centered moving average over the valid samples of each window."""
    kernel = np.ones(window)
    weight = np.convolve(valid.astype(float), kernel, mode="same")
    out = values.copy()
    for c in range(values.shape[1]):
        total = np.convolve(np.where(valid, values[:, c], 0.0), kernel, mode="same")
        out[valid, c] = total[valid] / weight[valid]
    return out


def filter_frames(
    result: dict,
    min_visibility: float = MIN_VISIBILITY,
    max_gap: int = MAX_GAP_FRAMES,
    window: int = SMOOTH_WINDOW,
) -> dict:
    """Return a filtered copy of an `AnalysisResult`-shaped dict (input untouched).

    Landmarks left missing are omitted from ``landmarks`` and any angle that
    needs one is omitted from ``angles``. ``pose_detected`` keeps the raw
    MediaPipe verdict, even for frames whose landmarks were interpolated.
    ``window`` is rounded up to an odd number.
    """
    frames = result["frames"]
    n = len(frames)
    window = max(1, window if window % 2 else window + 1)
    names = {name for f in frames for name in f["landmarks"]}
    kept: list[dict] = [{} for _ in range(n)]

    for name in names:
        xyz = np.zeros((n, 3))
        vis = np.zeros(n)
        valid = np.zeros(n, dtype=bool)
        for i, f in enumerate(frames):
            lm = f["landmarks"].get(name)
            if lm and lm["visibility"] >= min_visibility:
                xyz[i] = lm["x"], lm["y"], lm["z"]
                vis[i] = lm["visibility"]
                valid[i] = True
        data = np.column_stack([xyz, vis])
        data, valid = _fill_gaps(data, valid, max_gap)
        data[:, :3] = _smooth(data[:, :3], valid, window)
        for i in np.flatnonzero(valid):
            x, y, z, v = (round(float(c), COORD_PRECISION) for c in data[i])
            kept[i][name] = {"x": x, "y": y, "z": z, "visibility": v}

    width, height = result["width"], result["height"]
    out_frames = [
        {**f, "landmarks": kept[i], "angles": frame_angles(kept[i], width, height)}
        for i, f in enumerate(frames)
    ]
    return {**result, "frames": out_frames}
