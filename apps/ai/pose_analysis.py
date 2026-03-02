"""MediaPipe pose analysis module.

Expose `analyze(video_path)` qui retourne un dict JSON-sérialisable
contenant les landmarks et angles par frame.
Peut aussi tourner en standalone : `python mediapipe.py <video>`
"""

import cv2
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision
import json
import numpy as np
import os
import sys

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(BASE_DIR, "pose_landmarker.task")

LANDMARKS = {
    11: "left_shoulder", 12: "right_shoulder",
    13: "left_elbow",    14: "right_elbow",
    15: "left_wrist",    16: "right_wrist",
    23: "left_hip",      24: "right_hip",
    25: "left_knee",     26: "right_knee",
    27: "left_ankle",    28: "right_ankle",
}


# ─── Geometry helpers ────────────────────────────────────────────
def _vec3(a, b):
    return [b["x"] - a["x"], b["y"] - a["y"], b["z"] - a["z"]]


def _magnitude(v):
    return float(np.linalg.norm(v))


def _normalize(v):
    m = _magnitude(v)
    return [x / m for x in v] if m > 0 else v


def _angle_between(v1, v2):
    u1, u2 = _normalize(v1), _normalize(v2)
    return float(np.degrees(np.arccos(np.clip(np.dot(u1, u2), -1, 1))))


# ─── Per-frame processing ───────────────────────────────────────
def _process_pose(landmarks_raw):
    lm = {}
    for idx, name in LANDMARKS.items():
        l = landmarks_raw[idx]
        if l.presence < 0.3:
            continue
        lm[name] = {
            "x": round(l.x, 5),
            "y": round(l.y, 5),
            "z": round(l.z, 5),
            "presence": round(l.presence, 3),
        }

    angles = {}
    if all(k in lm for k in ("left_shoulder", "left_elbow", "left_wrist")):
        v1 = _vec3(lm["left_elbow"], lm["left_shoulder"])
        v2 = _vec3(lm["left_elbow"], lm["left_wrist"])
        angles["left_elbow"] = round(_angle_between(v1, v2), 2)

    return {"landmarks": lm, "angles": angles}


# ─── Public API ──────────────────────────────────────────────────
def analyze(video_path: str) -> dict:
    """Run MediaPipe pose estimation on *video_path*.

    Returns a dict ``{"frames": [...]}``.
    Raises ``FileNotFoundError`` / ``RuntimeError`` on bad input.
    """
    if not os.path.exists(video_path):
        raise FileNotFoundError(f"Fichier vidéo introuvable : {video_path}")

    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        raise RuntimeError(
            f"OpenCV ne peut pas ouvrir la vidéo : {video_path}. "
            "Vérifie tes codecs (ffmpeg)."
        )

    fps = cap.get(cv2.CAP_PROP_FPS)
    if fps <= 0:
        fps = 30

    n_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    print(f"[mediapipe] Vidéo chargée : {n_frames} frames à {fps} FPS")

    base_options = python.BaseOptions(model_asset_path=MODEL_PATH)
    options = vision.PoseLandmarkerOptions(
        base_options=base_options,
        running_mode=vision.RunningMode.VIDEO,
    )

    try:
        with vision.PoseLandmarker.create_from_options(options) as landmarker:
            output: dict = {"frames": []}

            for i in range(n_frames):
                ret, frame = cap.read()
                if not ret:
                    print(f"[mediapipe] Lecture interrompue à la frame {i}")
                    break

                rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                mp_image = mp.Image(
                    image_format=mp.ImageFormat.SRGB, data=rgb_frame
                )

                timestamp_ms = int((i / fps) * 1000)
                result = landmarker.detect_for_video(mp_image, timestamp_ms)

                frame_data = {
                    "frame": i,
                    "timestamp_ms": timestamp_ms,
                    "pose_detected": False,
                }

                if result.pose_landmarks:
                    frame_data["pose_detected"] = True
                    frame_data.update(_process_pose(result.pose_landmarks[0]))

                output["frames"].append(frame_data)

                if i % 30 == 0:
                    det = "OK" if result.pose_landmarks else "NO_POSE"
                    print(f"[mediapipe] {i}/{n_frames} ({det})")

            print(
                f"[mediapipe] Terminé — {len(output['frames'])} frames analysées"
            )
            return output
    finally:
        cap.release()


# ─── Standalone usage ────────────────────────────────────────────
if __name__ == "__main__":
    path = sys.argv[1] if len(sys.argv) > 1 else os.path.join(BASE_DIR, "vid.mp4")
    result = analyze(path)
    out = os.path.join(BASE_DIR, "biomechanics.json")
    with open(out, "w") as f:
        json.dump(result, f, indent=2)
    print(f"Sauvegardé dans {out}")