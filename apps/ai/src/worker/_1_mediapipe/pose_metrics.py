# @date 2026-11-01
# @file pose_metrics.py
# @brief File description.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""Step A3: limb speeds, arm extension and aggregated metrics."""

import numpy as np

from worker._1_mediapipe.pose_geometry import to_px

#: A frame whose arm extension is below this counts as "bent arm".
BENT_ARM_THRESHOLD = 0.8
#: Joints whose speed is reported.
SPEED_JOINTS = ("left_wrist", "right_wrist", "left_ankle", "right_ankle")
PRECISION = 4


def _torso_length(frames: list[dict], width: int, height: int) -> float | None:
    """Median shoulder-hip distance in pixels over the video, or ``None`` if never seen."""
    lengths = []
    for f in frames:
        lm = f["landmarks"]
        if all(k in lm for k in ("left_shoulder", "right_shoulder", "left_hip", "right_hip")):
            shoulders = (to_px(lm["left_shoulder"], width, height) + to_px(lm["right_shoulder"], width, height)) / 2
            hips = (to_px(lm["left_hip"], width, height) + to_px(lm["right_hip"], width, height)) / 2
            lengths.append(float(np.linalg.norm(shoulders - hips)))
    return float(np.median(lengths)) if lengths else None


def _extension(lm: dict, side: str, width: int, height: int) -> float | None:
    """Shoulder-wrist distance over shoulder-elbow + elbow-wrist, in [0, 1]."""
    keys = (f"{side}_shoulder", f"{side}_elbow", f"{side}_wrist")
    if not all(k in lm for k in keys):
        return None
    s, e, w = (to_px(lm[k], width, height) for k in keys)
    arm = np.linalg.norm(e - s) + np.linalg.norm(w - e)
    return None if arm == 0 else float(min(1.0, np.linalg.norm(w - s) / arm))


def _mean(values: list[float]) -> float | None:
    return round(float(np.mean(values)), PRECISION) if values else None


def compute_metrics(result: dict, bent_arm_threshold: float = BENT_ARM_THRESHOLD) -> dict:
    """Return a copy of an `AnalysisResult`-shaped dict with per-frame ``speeds`` /
    ``arm_extension`` and a ``metrics`` block. Uncomputable values are omitted.

    Speeds are in torso lengths per second (torso = median shoulder-hip distance),
    computed in pixels between consecutive frames.
    """
    frames, fps = result["frames"], result["fps"]
    width, height = result["width"], result["height"]
    torso = _torso_length(frames, width, height)

    out_frames = []
    speed_samples: dict[str, list[float]] = {}
    ext_samples: dict[str, list[float]] = {"left": [], "right": []}
    for i, f in enumerate(frames):
        lm = f["landmarks"]
        new = dict(f)
        if torso and i > 0 and frames[i - 1]["frame"] == f["frame"] - 1:
            prev = frames[i - 1]["landmarks"]
            speeds = {}
            for j in SPEED_JOINTS:
                if j in lm and j in prev:
                    dist = np.linalg.norm(to_px(lm[j], width, height) - to_px(prev[j], width, height))
                    speeds[j] = round(float(dist / torso * fps), PRECISION)
                    speed_samples.setdefault(j, []).append(speeds[j])
            if speeds:
                new["speeds"] = speeds
        ext = {s: _extension(lm, s, width, height) for s in ("left", "right")}
        ext = {s: v for s, v in ext.items() if v is not None}
        if ext:
            new["arm_extension"] = {s: round(v, PRECISION) for s, v in ext.items()}
            for s, v in ext.items():
                ext_samples[s].append(v)
        out_frames.append(new)

    metrics: dict = {
        "duration_ms": int(len(frames) / fps * 1000) if fps > 0 else 0,
        "pose_detection_rate": round(sum(f["pose_detected"] for f in frames) / len(frames), PRECISION)
        if frames
        else 0.0,
    }
    if speed_samples:
        metrics["avg_speed"] = {j: _mean(v) for j, v in speed_samples.items()}
    if any(ext_samples.values()):
        metrics["avg_arm_extension"] = {s: _mean(v) for s, v in ext_samples.items() if v}
        metrics["bent_arm_ratio"] = {
            s: _mean([float(x < bent_arm_threshold) for x in v]) for s, v in ext_samples.items() if v
        }
    return {**result, "frames": out_frames, "metrics": metrics}
