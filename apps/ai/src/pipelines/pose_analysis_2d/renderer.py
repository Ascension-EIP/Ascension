# @date 2026-09-07
# @file renderer.py
# @brief 2D skeleton video annotation and rendering.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""2D skeleton video annotation and rendering."""

import json
import logging
from pathlib import Path
from typing import Any

import cv2

from src.pipelines.pose_analysis_2d.constants import BODY_CONNECTIONS

logger = logging.getLogger("ai-worker.render.2d")


def render_annotated_video(
    video_path: str,
    analysis_data: dict[str, Any] | str,
    output_path: str,
) -> None:
    """Render an annotated MP4 video with the 2D skeleton overlay.

    Args:
        video_path: Path to the original video file.
        analysis_data: Dict or path to JSON file produced by pose analysis.
        output_path: Destination path for the annotated video.
    """
    if isinstance(analysis_data, (str, Path)):
        with open(analysis_data) as f:
            data = json.load(f)
    else:
        data = analysis_data

    frames_index = {fd["frame"]: fd for fd in data.get("frames", [])}

    cap = cv2.VideoCapture(str(video_path))
    if not cap.isOpened():
        raise RuntimeError(f"Cannot open video: {video_path}")

    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    fps = cap.get(cv2.CAP_PROP_FPS) or 30.0
    n_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))

    fourcc = cv2.VideoWriter_fourcc(*"mp4v")
    writer = cv2.VideoWriter(str(output_path), fourcc, fps, (width, height))

    logger.info("Encoding %d annotated frames → %s", n_frames, output_path)

    frame_idx = 0
    try:
        while True:
            ret, frame = cap.read()
            if not ret:
                break

            fd = frames_index.get(frame_idx, {})
            if fd.get("pose_detected") and "landmarks" in fd:
                lm = fd["landmarks"]
                pts = {
                    name: (int(v["x"] * width), int(v["y"] * height))
                    for name, v in lm.items()
                }

                # Draw skeleton connections
                for a, b in BODY_CONNECTIONS:
                    sa, sb = str(a), str(b)
                    if sa in pts and sb in pts:
                        cv2.line(frame, pts[sa], pts[sb], (0, 255, 0), 2, cv2.LINE_AA)

                # Draw landmark dots
                for px, py in pts.values():
                    cv2.circle(frame, (px, py), 5, (0, 100, 255), -1, cv2.LINE_AA)
                    cv2.circle(frame, (px, py), 5, (255, 255, 255), 1, cv2.LINE_AA)

                # Draw joint angles
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

            # Draw frame counter
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
            frame_idx += 1
    finally:
        cap.release()
        writer.release()
    logger.info("Finished annotated video rendering: %s", output_path)
