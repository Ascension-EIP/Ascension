"""MediaPipe pose analysis module.

Expose `analyze(video_path)` qui retourne un dict JSON-sérialisable
contenant les landmarks et angles par frame.
Peut aussi tourner en standalone : `python pose_analysis.py <video>`
"""

import cv2
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision
import json
import numpy as np
import os

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODEL_PATH = os.path.join(BASE_DIR, "pose_landmarker.task")


# ─── Landmark IDs ────────────────────────────────────────────────
# LM constants ARE the MediaPipe indices and the JSON keys (as str).
# LM.NAMES maps each index to a human-readable label for debugging
# and rendering — never written to the output JSON.
class LM:
    L_SHOULDER = 11
    R_SHOULDER = 12
    L_ELBOW = 13
    R_ELBOW = 14
    L_WRIST = 15
    R_WRIST = 16
    L_HIP = 23
    R_HIP = 24
    L_KNEE = 25
    R_KNEE = 26
    L_ANKLE = 27
    R_ANKLE = 28

    NAMES = {
        11: "left_shoulder",
        12: "right_shoulder",
        13: "left_elbow",
        14: "right_elbow",
        15: "left_wrist",
        16: "right_wrist",
        23: "left_hip",
        24: "right_hip",
        25: "left_knee",
        26: "right_knee",
        27: "left_ankle",
        28: "right_ankle",
    }


# Pairs of landmark names to connect when drawing the skeleton overlay.
_BODY_CONNECTIONS = [
    (LM.L_SHOULDER, LM.R_SHOULDER),
    (LM.L_SHOULDER, LM.L_ELBOW),
    (LM.L_ELBOW, LM.L_WRIST),
    (LM.R_SHOULDER, LM.R_ELBOW),
    (LM.R_ELBOW, LM.R_WRIST),
    (LM.L_SHOULDER, LM.L_HIP),
    (LM.R_SHOULDER, LM.R_HIP),
    (LM.L_HIP, LM.R_HIP),
    (LM.L_HIP, LM.L_KNEE),
    (LM.L_KNEE, LM.L_ANKLE),
    (LM.R_HIP, LM.R_KNEE),
    (LM.R_KNEE, LM.R_ANKLE),
]


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
    for idx in LM.NAMES:
        lnd = landmarks_raw[idx]
        if lnd.presence < 0.8:
            continue
        lm[str(idx)] = {
            "x": round(lnd.x, 3),
            "y": round(lnd.y, 3),
            "z": round(lnd.z, 3),
            "pres": round(lnd.presence, 3),
        }

    angles = {}
    s_sh, s_el, s_wr = str(LM.L_SHOULDER), str(LM.L_ELBOW), str(LM.L_WRIST)
    if all(k in lm for k in (s_sh, s_el, s_wr)):
        v1 = _vec3(lm[s_el], lm[s_sh])
        v2 = _vec3(lm[s_el], lm[s_wr])
        angles[s_el] = round(_angle_between(v1, v2), 2)

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

    # Analyse at most TARGET_FPS frames per second of video.
    # On a 60 fps video this skips every other frame; on a 30 fps video
    # nothing is skipped.  Keeps processing time proportional to duration
    # rather than source frame-rate.
    TARGET_FPS = 15
    frame_step = max(1, int(round(fps / TARGET_FPS)))
    effective_frames = (n_frames + frame_step - 1) // frame_step

    # Resize frames to max this width before sending to MediaPipe.
    # Reduces memory consumption and speeds up inference significantly.
    # MediaPipe Lite handles 256-512 px inputs well.
    MAX_WIDTH = 640

    print(
        f"[mediapipe] Vidéo : {n_frames} frames @ {fps:.1f} FPS — "
        f"analyse 1/{frame_step} frames ({effective_frames} frames effectives, max {MAX_WIDTH}px)"
    )

    base_options = python.BaseOptions(model_asset_path=MODEL_PATH)
    options = vision.PoseLandmarkerOptions(
        base_options=base_options,
        running_mode=vision.RunningMode.VIDEO,
    )

    try:
        with vision.PoseLandmarker.create_from_options(options) as landmarker:
            frames_list = []
            analyzed = 0

            # Seek directly to each target frame instead of decoding every
            # frame sequentially.  This avoids allocating decompressed numpy
            # arrays for skipped frames and is the primary memory saving.
            i = 0
            while i < n_frames:
                cap.set(cv2.CAP_PROP_POS_FRAMES, i)
                ret, frame = cap.read()
                if not ret:
                    print(f"[mediapipe] Lecture interrompue à la frame {i}")
                    break

                # Downscale to MAX_WIDTH to reduce memory and speed up inference
                h, w = frame.shape[:2]
                if w > MAX_WIDTH:
                    scale = MAX_WIDTH / w
                    frame = cv2.resize(
                        frame,
                        (MAX_WIDTH, int(h * scale)),
                        interpolation=cv2.INTER_AREA,
                    )

                rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                del frame  # release original BGR array immediately

                mp_image = mp.Image(
                    image_format=mp.ImageFormat.SRGB, data=rgb_frame
                )
                del rgb_frame  # release after MediaPipe copies it

                timestamp_ms = int((i / fps) * 1000)
                result = landmarker.detect_for_video(mp_image, timestamp_ms)
                del mp_image

                frame_data = {
                    "frame": i,
                    "timestamp_ms": timestamp_ms,
                    "pose_detected": False,
                }

                if result.pose_landmarks:
                    frame_data["pose_detected"] = True
                    frame_data.update(_process_pose(result.pose_landmarks[0]))

                frames_list.append(frame_data)
                analyzed += 1

                if analyzed % 30 == 0:
                    det = "OK" if result.pose_landmarks else "NO_POSE"
                    print(f"[mediapipe] {analyzed}/{effective_frames} ({det})")

                i += frame_step

            print(f"[mediapipe] Terminé — {analyzed} frames analysées")
            return {"frames": frames_list}
    finally:
        cap.release()


# ─── Annotated video rendering ──────────────────────────────────
def render_annotated_video(
    video_path: str,
    json_path: str,
    output_path: str,
) -> None:
    """Render an annotated MP4 with skeleton overlay baked in.

    Reads the JSON produced by :func:`analyze`, draws the skeleton on
    every frame, and writes the result to *output_path*.  No GUI window
    is opened — just open the output file in any video player.

    Args:
        video_path:   Path to the original video file.
        json_path:    Path to the biomechanics JSON produced by
                      :func:`analyze`.
        output_path:  Destination MP4 file (e.g. ``vid-postanalyse.mp4``).
    """
    with open(json_path, "r") as f:
        data = json.load(f)

    frames_index = {fd["frame"]: fd for fd in data["frames"]}

    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        raise RuntimeError(f"Cannot open video: {video_path}")

    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    fps = cap.get(cv2.CAP_PROP_FPS) or 30
    n_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))

    fourcc = cv2.VideoWriter_fourcc(*"mp4v")
    writer = cv2.VideoWriter(output_path, fourcc, fps, (width, height))

    print(f"[render] Encodage de {n_frames} frames → {output_path}")

    frame_idx = 0
    while True:
        ret, frame = cap.read()
        if not ret:
            break

        fd = frames_index.get(frame_idx, {})
        if fd.get("pose_detected") and "landmarks" in fd:
            lm = fd["landmarks"]

            # Normalised [0,1] → pixel coords
            pts = {
                name: (int(v["x"] * width), int(v["y"] * height))
                for name, v in lm.items()
            }

            # Skeleton lines (LM constants are ints; JSON keys are str)
            for a, b in _BODY_CONNECTIONS:
                sa, sb = str(a), str(b)
                if sa in pts and sb in pts:
                    cv2.line(
                        frame, pts[sa], pts[sb], (0, 255, 0), 2, cv2.LINE_AA
                    )

            # Landmark dots
            for px, py in pts.values():
                cv2.circle(frame, (px, py), 5, (0, 100, 255), -1, cv2.LINE_AA)
                cv2.circle(frame, (px, py), 5, (255, 255, 255), 1, cv2.LINE_AA)

            # Angle labels (joint keys are already str from JSON)
            for joint, deg in fd.get("angles", {}).items():
                if joint in pts:
                    px, py = pts[joint]
                    cv2.putText(
                        frame,
                        f"{deg:.0f}\u00b0",
                        (px + 8, py - 8),
                        cv2.FONT_HERSHEY_SIMPLEX,
                        0.5,
                        (255, 255, 0),
                        1,
                        cv2.LINE_AA,
                    )

        # Frame counter
        cv2.putText(
            frame,
            f"frame {frame_idx}",
            (10, 25),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.6,
            (200, 200, 200),
            1,
            cv2.LINE_AA,
        )

        writer.write(frame)

        if frame_idx % 30 == 0:
            print(f"[render] {frame_idx}/{n_frames}")

        frame_idx += 1

    cap.release()
    writer.release()
    print(f"[render] Terminé — {output_path}")


# ─── Standalone usage ────────────────────────────────────────────
if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(
        description="Ascension — analyse de pose MediaPipe"
    )
    parser.add_argument(
        "video",
        nargs="?",
        default=os.path.join(BASE_DIR, "vid.mp4"),
        help="Chemin vers la vidéo d'entrée (défaut : vid.mp4)",
    )
    parser.add_argument(
        "-o",
        "--output",
        default=os.path.join(BASE_DIR, "biomechanics.json"),
        help="Chemin du JSON de sortie (défaut : biomechanics.json)",
    )
    parser.add_argument(
        "--render",
        action="store_true",
        help="Générer la vidéo annotée après l'analyse",
    )
    parser.add_argument(
        "--render-only",
        metavar="JSON",
        help="Sauter l'analyse — générer la vidéo depuis un JSON existant",
    )
    parser.add_argument(
        "--render-output",
        metavar="PATH",
        help="Chemin de la vidéo annotée (défaut : <video>-postanalyse.mp4)",
    )
    args = parser.parse_args()

    # Dérive le chemin de sortie vidéo depuis le nom de la vidéo source
    def _render_out(video: str, override: str | None) -> str:
        if override:
            return override
        base, _ = os.path.splitext(video)
        return f"{base}-postanalyse.mp4"

    if args.render_only:
        render_annotated_video(
            args.video,
            args.render_only,
            _render_out(args.video, args.render_output),
        )
    else:
        result = analyze(args.video)
        with open(args.output, "w") as f:
            json.dump(result, f)
        print(f"Sauvegardé dans {args.output}")
        if args.render:
            render_annotated_video(
                args.video,
                args.output,
                _render_out(args.video, args.render_output),
            )
