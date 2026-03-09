"""SAM 3D Body pose analysis module.

Expose ``create_estimator`` (one-time model load) and ``analyze`` (per-video
inference) so the consumer can load the model once and process many videos.

Also provides ``render_annotated_video`` to bake 2D skeleton overlays onto a
video from a previously-saved JSON.

Standalone usage::

    python pose_analysis_v2.py <video> --checkpoint_path ./checkpoints/sam-3d-body-dinov3/model.ckpt
"""

import argparse
import json
import os
import time

import cv2
import numpy as np
import torch
from sam_3d_body import load_sam_3d_body, SAM3DBodyEstimator
from sam_3d_body.metadata.mhr70 import mhr_names
from tools.utils import setup_visualizer
from tqdm import tqdm

BASE_DIR = os.path.dirname(os.path.abspath(__file__))


# ─── MHR-70 keypoint indices (main body) ────────────────────────
class KP:
    NOSE = 0
    L_EYE = 1
    R_EYE = 2
    L_EAR = 3
    R_EAR = 4
    L_SHOULDER = 5
    R_SHOULDER = 6
    L_ELBOW = 7
    R_ELBOW = 8
    L_HIP = 9
    R_HIP = 10
    L_KNEE = 11
    R_KNEE = 12
    L_ANKLE = 13
    R_ANKLE = 14
    R_WRIST = 41
    L_WRIST = 62

    NAMES = {
        0: "nose",
        5: "left_shoulder", 6: "right_shoulder",
        7: "left_elbow",    8: "right_elbow",
        9: "left_hip",      10: "right_hip",
        11: "left_knee",    12: "right_knee",
        13: "left_ankle",   14: "right_ankle",
        41: "right_wrist",  62: "left_wrist",
    }


# Skeleton lines for rendering
_BODY_CONNECTIONS = [
    (KP.NOSE, KP.L_SHOULDER),
    (KP.NOSE, KP.R_SHOULDER),
    (KP.L_SHOULDER, KP.R_SHOULDER),
    (KP.L_SHOULDER, KP.L_ELBOW),
    (KP.L_ELBOW, KP.L_WRIST),
    (KP.R_SHOULDER, KP.R_ELBOW),
    (KP.R_ELBOW, KP.R_WRIST),
    (KP.L_SHOULDER, KP.L_HIP),
    (KP.R_SHOULDER, KP.R_HIP),
    (KP.L_HIP, KP.R_HIP),
    (KP.L_HIP, KP.L_KNEE),
    (KP.L_KNEE, KP.L_ANKLE),
    (KP.R_HIP, KP.R_KNEE),
    (KP.R_KNEE, KP.R_ANKLE),
]

# Angle definitions: (name, idx_a, idx_joint, idx_b)
_ANGLE_DEFS = [
    ("left_elbow",     KP.L_SHOULDER, KP.L_ELBOW,    KP.L_WRIST),
    ("right_elbow",    KP.R_SHOULDER, KP.R_ELBOW,    KP.R_WRIST),
    ("left_shoulder",  KP.L_ELBOW,    KP.L_SHOULDER, KP.L_HIP),
    ("right_shoulder", KP.R_ELBOW,    KP.R_SHOULDER, KP.R_HIP),
    ("left_knee",      KP.L_HIP,     KP.L_KNEE,     KP.L_ANKLE),
    ("right_knee",     KP.R_HIP,     KP.R_KNEE,     KP.R_ANKLE),
    ("left_hip",       KP.L_SHOULDER, KP.L_HIP,     KP.L_KNEE),
    ("right_hip",      KP.R_SHOULDER, KP.R_HIP,     KP.R_KNEE),
]

# Map angle name → keypoint index (for label placement during rendering)
_ANGLE_JOINT_MAP = {name: joint for name, _, joint, _ in _ANGLE_DEFS}


# ─── Geometry helpers ────────────────────────────────────────────
def _angle_between(v1, v2):
    n1, n2 = np.linalg.norm(v1), np.linalg.norm(v2)
    if n1 == 0 or n2 == 0:
        return 0.0
    cos = np.clip(np.dot(v1, v2) / (n1 * n2), -1, 1)
    return float(np.degrees(np.arccos(cos)))


def _compute_angles(kpts_3d):
    """Compute joint angles from 3D keypoints (Nx3 array)."""
    angles = {}
    for name, a, joint, b in _ANGLE_DEFS:
        v1 = kpts_3d[a] - kpts_3d[joint]
        v2 = kpts_3d[b] - kpts_3d[joint]
        angles[name] = round(_angle_between(v1, v2), 2)
    return angles


# ─── Model setup (call once) ────────────────────────────────────
def create_estimator(
    checkpoint_path: str = "",
    mhr_path: str = "",
    detector_name: str = "",
    segmentor_name: str = "",
    fov_name: str = "",
    detector_path: str = "",
    segmentor_path: str = "",
    fov_path: str = "",
) -> SAM3DBodyEstimator:
    """Load SAM 3D Body model and auxiliary modules.

    Returns a ready-to-use :class:`SAM3DBodyEstimator`.
    """
    checkpoint_path = checkpoint_path or os.environ.get(
        "SAM3D_CHECKPOINT_PATH",
        os.path.join(BASE_DIR, "checkpoints/sam-3d-body-dinov3/model.ckpt"),
    )
    mhr_path = mhr_path or os.environ.get(
        "SAM3D_MHR_PATH",
        os.path.join(BASE_DIR, "checkpoints/sam-3d-body-dinov3/assets/mhr_model.pt"),
    )
    detector_path = detector_path or os.environ.get("SAM3D_DETECTOR_PATH", "")
    segmentor_path = segmentor_path or os.environ.get("SAM3D_SEGMENTOR_PATH", "")
    fov_path = fov_path or os.environ.get("SAM3D_FOV_PATH", "")

    device = torch.device("cuda") if torch.cuda.is_available() else torch.device("cpu")
    print(f"[sam3d] Loading model from {checkpoint_path} on {device}...")
    model, model_cfg = load_sam_3d_body(checkpoint_path, device=device, mhr_path=mhr_path)

    human_detector, human_segmentor, fov_estimator = None, None, None

    if detector_name:
        from tools.build_detector import HumanDetector
        human_detector = HumanDetector(name=detector_name, device=device, path=detector_path)

    if segmentor_name and ((segmentor_name == "sam2" and len(segmentor_path)) or segmentor_name != "sam2"):
        from tools.build_sam import HumanSegmentor
        human_segmentor = HumanSegmentor(name=segmentor_name, device=device, path=segmentor_path)

    if fov_name:
        from tools.build_fov_estimator import FOVEstimator
        fov_estimator = FOVEstimator(name=fov_name, device=device, path=fov_path)

    estimator = SAM3DBodyEstimator(
        sam_3d_body_model=model,
        model_cfg=model_cfg,
        human_detector=human_detector,
        human_segmentor=human_segmentor,
        fov_estimator=fov_estimator,
    )
    print("[sam3d] Model loaded.")
    return estimator


# ─── Per-frame output serialisation ─────────────────────────────
def _serialise_frame_outputs(outputs):
    """Convert SAM 3D Body outputs for one frame to JSON-serialisable dicts."""
    people = []
    for person in outputs:
        kpts_2d = person["pred_keypoints_2d"]   # (N, 2) pixel coords
        kpts_3d = person["pred_keypoints_3d"]   # (N, 3)
        bbox = person["bbox"]                   # (4,)

        angles = _compute_angles(kpts_3d)

        # Only keep the main body keypoints in a named dict for convenience
        landmarks = {}
        for idx, name in KP.NAMES.items():
            if idx < len(kpts_2d):
                landmarks[name] = {
                    "x": round(float(kpts_2d[idx][0]), 2),
                    "y": round(float(kpts_2d[idx][1]), 2),
                    "z": round(float(kpts_3d[idx][2]), 5) if idx < len(kpts_3d) else 0.0,
                }

        people.append({
            "bbox": [round(float(x), 2) for x in bbox],
            "landmarks": landmarks,
            "keypoints_2d": [[round(float(x), 2) for x in kp] for kp in kpts_2d],
            "keypoints_3d": [[round(float(x), 5) for x in kp] for kp in kpts_3d],
            "focal_length": round(float(person["focal_length"]), 4),
            "pred_cam_t": [round(float(x), 5) for x in person["pred_cam_t"]],
            "angles": angles,
        })
    return people


# ─── Public API — video analysis ─────────────────────────────────
def analyze(
    video_path: str,
    estimator: SAM3DBodyEstimator | None = None,
    sample_every: int = 3,
    **model_kwargs,
) -> dict:
    """Run SAM 3D Body pose estimation on *video_path*.

    If *estimator* is ``None`` a new one is created from *model_kwargs*
    (or environment variables).  Pass a pre-built estimator to avoid
    reloading the model for every video.

    Args:
        video_path:   Path to the input video.
        estimator:    Pre-built SAM3DBodyEstimator (avoids reloading the model).
        sample_every: Run inference only on 1 frame out of every N.
                      Skipped frames reuse the last inferred result.
                      ``1`` (default) processes every frame.

    Returns ``{"fps": …, "width": …, "height": …, "frames": [...]}``.
    """
    if not os.path.exists(video_path):
        raise FileNotFoundError(f"Video file not found: {video_path}")

    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        raise RuntimeError(f"Cannot open video: {video_path}")

    fps = cap.get(cv2.CAP_PROP_FPS)
    if fps <= 0:
        fps = 30
    n_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    print(f"[sam3d] Video loaded: {n_frames} frames at {fps} FPS ({width}x{height})")
    if sample_every > 1:
        print(f"[sam3d] Subsampling: inference every {sample_every} frames "
              f"(~{n_frames // sample_every} inferred)")

    if estimator is None:
        estimator = create_estimator(**model_kwargs)

    output = {"fps": fps, "width": width, "height": height, "frames": []}
    last_people: list = []

    for i in tqdm(range(n_frames), desc="[sam3d] Processing"):
        ret, frame_bgr = cap.read()
        if not ret:
            print(f"[sam3d] Read interrupted at frame {i}")
            break

        timestamp_ms = int((i / fps) * 1000)

        if i % sample_every == 0:
            # process_one_image expects an RGB numpy array.
            frame_rgb = cv2.cvtColor(frame_bgr, cv2.COLOR_BGR2RGB)
            try:
                outputs = estimator.process_one_image(frame_rgb)
                last_people = _serialise_frame_outputs(outputs)
            except Exception as e:
                print(f"[sam3d] Frame {i} failed: {e}")
                last_people = []

        output["frames"].append({
            "frame": i,
            "timestamp_ms": timestamp_ms,
            "sampled": i % sample_every == 0,
            "n_people": len(last_people),
            "people": last_people,
        })

    cap.release()
    print(f"[sam3d] Done — {len(output['frames'])} frames processed")
    return output


# ─── Annotated video rendering ──────────────────────────────────
def render_annotated_video(
    video_path: str,
    json_path: str,
    output_path: str,
) -> None:
    """Render an annotated MP4 with SAM 3D Body skeleton overlay.

    Reads the JSON produced by :func:`analyze`, draws a skeleton on
    every frame, and writes the result to *output_path*.

    Args:
        video_path:   Path to the original video file.
        json_path:    Path to the JSON produced by :func:`analyze`.
        output_path:  Destination MP4 file.
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

    print(f"[render] Encoding {n_frames} frames → {output_path}")

    frame_idx = 0
    while True:
        ret, frame = cap.read()
        if not ret:
            break

        fd = frames_index.get(frame_idx, {})
        for pid, person in enumerate(fd.get("people", [])):
            kpts_2d = person["keypoints_2d"]   # list of [x, y]
            bbox = person["bbox"]

            # --- Skeleton lines ---
            for a, b in _BODY_CONNECTIONS:
                if a < len(kpts_2d) and b < len(kpts_2d):
                    pt1 = (int(kpts_2d[a][0]), int(kpts_2d[a][1]))
                    pt2 = (int(kpts_2d[b][0]), int(kpts_2d[b][1]))
                    cv2.line(frame, pt1, pt2, (0, 255, 0), 2, cv2.LINE_AA)

            # --- Keypoint dots (main body only) ---
            for idx in KP.NAMES:
                if idx < len(kpts_2d):
                    px, py = int(kpts_2d[idx][0]), int(kpts_2d[idx][1])
                    cv2.circle(frame, (px, py), 5, (0, 100, 255), -1, cv2.LINE_AA)
                    cv2.circle(frame, (px, py), 5, (255, 255, 255), 1, cv2.LINE_AA)

            # --- Bounding box ---
            cv2.rectangle(
                frame,
                (int(bbox[0]), int(bbox[1])),
                (int(bbox[2]), int(bbox[3])),
                (0, 255, 0), 2,
            )
            cv2.putText(
                frame, f"Person {pid}",
                (int(bbox[0]), int(bbox[1] - 10)),
                cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 0), 2,
            )

            # --- Angle labels ---
            for angle_name, deg in person.get("angles", {}).items():
                kp_idx = _ANGLE_JOINT_MAP.get(angle_name)
                if kp_idx is not None and kp_idx < len(kpts_2d):
                    px, py = int(kpts_2d[kp_idx][0]), int(kpts_2d[kp_idx][1])
                    cv2.putText(
                        frame, f"{deg:.0f}\u00b0",
                        (px + 8, py - 8),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.4,
                        (255, 255, 0), 1, cv2.LINE_AA,
                    )

        # Frame counter
        cv2.putText(
            frame, f"frame {frame_idx}", (10, 25),
            cv2.FONT_HERSHEY_SIMPLEX, 0.6, (200, 200, 200), 1, cv2.LINE_AA,
        )

        writer.write(frame)
        if frame_idx % 30 == 0:
            print(f"[render] {frame_idx}/{n_frames}")
        frame_idx += 1

    cap.release()
    writer.release()
    print(f"[render] Done — {output_path}")


# ─── Standalone usage ────────────────────────────────────────────
if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Ascension — SAM 3D Body pose analysis",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "video", nargs="?",
        default=os.path.join(BASE_DIR, "vid.mp4"),
        help="Path to input video (default: vid.mp4)",
    )
    parser.add_argument(
        "-o", "--output",
        default=os.path.join(BASE_DIR, "biomechanics.json"),
        help="JSON output path (default: biomechanics.json)",
    )
    parser.add_argument(
        "--checkpoint_path",
        default="./checkpoints/sam-3d-body-vith/model.ckpt",
        help="Path to SAM 3D Body model checkpoint",
    )
    parser.add_argument(
        "--mhr_path",
        default="./checkpoints/sam-3d-body-vith/assets/mhr_model.pt",
        help="Path to MHR model asset",
    )
    parser.add_argument("--detector_name", default="", help="Human detector name")
    parser.add_argument("--segmentor_name", default="", help="Human segmentor name (default: disabled)")
    parser.add_argument(
        "--sample-every", type=int, default=3, metavar="N",
        help="Run inference on 1 frame out of every N (default: 1 = every frame)",
    )
    parser.add_argument("--fov_name", default="", help="FOV estimator name")
    parser.add_argument("--detector_path", default="", help="Human detector path")
    parser.add_argument("--segmentor_path", default="", help="Human segmentor path")
    parser.add_argument("--fov_path", default="", help="FOV estimator path")
    parser.add_argument(
        "--render", action="store_true",
        help="Generate annotated video after analysis",
    )
    parser.add_argument(
        "--render-only", metavar="JSON",
        help="Skip analysis — render video from existing JSON",
    )
    parser.add_argument(
        "--render-output", metavar="PATH",
        help="Annotated video output path (default: <video>-postanalyse.mp4)",
    )
    args = parser.parse_args()

    def _render_out(video: str, override: str | None) -> str:
        if override:
            return override
        base, _ = os.path.splitext(video)
        return f"{base}-postanalyse.mp4"

    if args.render_only:
        render_annotated_video(
            args.video, args.render_only,
            _render_out(args.video, args.render_output),
        )
    else:
        estimator = create_estimator(
            checkpoint_path=args.checkpoint_path,
            mhr_path=args.mhr_path,
            detector_name=args.detector_name,
            segmentor_name=args.segmentor_name,
            fov_name=args.fov_name,
            detector_path=args.detector_path,
            segmentor_path=args.segmentor_path,
            fov_path=args.fov_path,
        )
        result = analyze(args.video, estimator=estimator, sample_every=args.sample_every)
        with open(args.output, "w") as f:
            json.dump(result, f)
        print(f"Saved to {args.output}")

        if args.render:
            render_annotated_video(
                args.video, args.output,
                _render_out(args.video, args.render_output),
            )
