# @date 2026-09-05
# @file renderer.py
# @brief SAM 3D Body video annotation and rendering.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""SAM 3D Body video annotation and rendering."""

import json
import logging
from pathlib import Path
from typing import Any

import cv2

from src.pipelines.pose_analysis_3d.constants import (
    ANGLE_JOINT_MAP,
    BODY_CONNECTIONS,
    KP,
)

logger = logging.getLogger("ai-worker.render.3d")


def render_annotated_video(
    video_path: str,
    analysis_data: dict[str, Any] | str,
    output_path: str,
) -> None:
    """Render an annotated MP4 video with SAM-3D skeleton and bounding boxes.

    Args:
        video_path: Path to the original video file.
        analysis_data: Dict or path to JSON produced by pose_analysis_3d.
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

    logger.info("Encoding %d annotated frames (3D) → %s", n_frames, output_path)

    frame_idx = 0
    try:
        while True:
            ret, frame = cap.read()
            if not ret:
                break

            fd = frames_index.get(frame_idx, {})
            for pid, person in enumerate(fd.get("people", [])):
                kpts_2d = person.get("keypoints_2d", [])
                bbox = person.get("bbox", [0, 0, 0, 0])

                # Draw skeleton lines
                for a, b in BODY_CONNECTIONS:
                    if a < len(kpts_2d) and b < len(kpts_2d):
                        pt1 = (int(kpts_2d[a][0]), int(kpts_2d[a][1]))
                        pt2 = (int(kpts_2d[b][0]), int(kpts_2d[b][1]))
                        cv2.line(frame, pt1, pt2, (0, 255, 0), 2, cv2.LINE_AA)

                # Draw keypoint dots
                for idx in KP.NAMES:
                    if idx < len(kpts_2d):
                        px, py = int(kpts_2d[idx][0]), int(kpts_2d[idx][1])
                        cv2.circle(frame, (px, py), 5, (0, 100, 255), -1, cv2.LINE_AA)
                        cv2.circle(frame, (px, py), 5, (255, 255, 255), 1, cv2.LINE_AA)

                # Draw bounding box
                if len(bbox) == 4:
                    cv2.rectangle(
                        frame,
                        (int(bbox[0]), int(bbox[1])),
                        (int(bbox[2]), int(bbox[3])),
                        (0, 255, 0),
                        2,
                    )
                    cv2.putText(
                        frame,
                        f"Person {pid}",
                        (int(bbox[0]), int(bbox[1] - 10)),
                        cv2.FONT_HERSHEY_SIMPLEX,
                        0.6,
                        (0, 255, 0),
                        2,
                    )

                # Draw angle labels
                for angle_name, deg in person.get("angles", {}).items():
                    kp_idx = ANGLE_JOINT_MAP.get(angle_name)
                    if kp_idx is not None and kp_idx < len(kpts_2d):
                        px, py = int(kpts_2d[kp_idx][0]), int(kpts_2d[kp_idx][1])
                        cv2.putText(
                            frame,
                            f"{deg:.0f}\u00b0",
                            (px + 8, py - 8),
                            cv2.FONT_HERSHEY_SIMPLEX,
                            0.4,
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
    logger.info("Finished annotated video rendering (3D): %s", output_path)
