# @date 2026-11-02
# @file _1_pose_skeleton.py
# @brief File description.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
import os
from collections.abc import Callable, Iterator
from pathlib import Path
from typing import Self

import cv2
import mediapipe as mp
from mediapipe.tasks.python import vision
from mediapipe.tasks.python.components.containers.landmark import NormalizedLandmark
from mediapipe.tasks.python.vision import drawing_styles, drawing_utils
from rich.progress import track

from common.utils.errors import PermanentError
from common.utils.logger import log
from worker._1_mediapipe.pose_geometry import frame_angles

PoseLandmark = vision.PoseLandmark

#: Number of decimal places kept for coordinates/visibility.
COORD_PRECISION = 4
#: ``apps/ai``, used to resolve relative paths independently of the cwd.
AI_ROOT = Path(__file__).resolve().parents[3]
DEFAULT_MODEL_PATH = "resources/pose_landmarker_full.task"
#: Used when the container reports no FPS.
DEFAULT_FPS = 30.0


def resolve_model_path() -> str:
    """Model path from ``POSE_MODEL_PATH`` (default: bundled model), relative to ``apps/ai``."""
    return str(AI_ROOT / os.environ.get("POSE_MODEL_PATH", DEFAULT_MODEL_PATH))


class PoseSkeleton:
    """Extract the 33-point skeleton of every frame of a video."""

    def __init__(self, model: str | None = None):
        self.model = model or resolve_model_path()
        self.fps: float = 0.0
        self.frame_size: tuple[int, int] = (0, 0)
        #: Payload ready to be stored in `analyses.result`
        #: (``{"fps", "width", "height", "frames"}``), raw (unfiltered).
        self.result: dict | None = None

    def create_landmarker(self):
        """Create a landmarker. One per video: VIDEO mode needs timestamps that
        increase over the whole landmarker lifetime, so it cannot be reused."""
        log.info("Initializing the mediapipe model.")
        options = vision.PoseLandmarkerOptions(
            base_options=mp.tasks.BaseOptions(model_asset_path=self.model),
            running_mode=vision.RunningMode.VIDEO,
            min_pose_detection_confidence=0.1,
            min_pose_presence_confidence=0.1,
            min_tracking_confidence=0.1,
        )
        return vision.PoseLandmarker.create_from_options(options)

    @staticmethod
    def format_landmarks(landmarks: list[NormalizedLandmark]) -> dict:
        """Serialize the landmarks as ``{name: {x, y, z, visibility}}``."""
        return {
            PoseLandmark(index).name.lower(): {
                "x": round(lm.x or 0.0, COORD_PRECISION),
                "y": round(lm.y or 0.0, COORD_PRECISION),
                "z": round(lm.z or 0.0, COORD_PRECISION),
                "visibility": round(lm.visibility or 0.0, COORD_PRECISION),
            }
            for index, lm in enumerate(landmarks)
            if index < len(PoseLandmark)
        }

    def format_frame(self, frame_index: int, timestamp_ms: int, result) -> dict:
        """Build a ``frames`` entry matching `analyses.result`."""
        poses = result.pose_landmarks
        landmarks = self.format_landmarks(poses[0] if poses else [])
        return {
            "frame": frame_index,
            "timestamp_ms": timestamp_ms,
            "pose_detected": bool(poses),
            "landmarks": landmarks,
            "angles": frame_angles(landmarks, *self.frame_size),
        }

    @staticmethod
    def read_frames(cap: cv2.VideoCapture) -> Iterator:
        """Yield frames until ``read()`` fails (the frame count can be wrong)."""
        while True:
            success, frame = cap.read()
            if not success:
                return
            yield frame

    @staticmethod
    def draw_landmarks(frame, detection_result) -> None:
        """Draw the skeleton on a BGR frame, in place."""
        for pose_landmarks in detection_result.pose_landmarks:
            drawing_utils.draw_landmarks(
                image=frame,
                landmark_list=pose_landmarks,
                connections=vision.PoseLandmarksConnections.POSE_LANDMARKS,
                landmark_drawing_spec=drawing_styles.get_default_pose_landmarks_style(),
                connection_drawing_spec=drawing_utils.DrawingSpec(color=(0, 255, 0), thickness=2),
            )

    def landmark_video(
        self,
        video_path: str,
        render_path: str | None = None,
        on_progress: Callable[[int], None] | None = None,
    ) -> list[dict]:
        """Detect the skeleton frame by frame and return the formatted frames.

        Frames are not kept: the optional render is written as we go.

        Raises:
            PermanentError: The video cannot be opened or has no readable frame.
        """
        log.info("Landmarking the video frame per frame.")
        cap = cv2.VideoCapture(video_path)
        writer = None
        try:
            if not cap.isOpened():
                raise PermanentError("Video cannot be opened")
            self.fps = cap.get(cv2.CAP_PROP_FPS)
            if not self.fps > 0:
                log.warning("Video reports no FPS, assuming %s.", DEFAULT_FPS)
                self.fps = DEFAULT_FPS
            # Only used for progress: the container may report a wrong count.
            total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
            frames: list[dict] = []
            last_percent = -1

            with self.create_landmarker() as landmarker:
                for index, frame in enumerate(
                    track(self.read_frames(cap), description="Landmarking frames...", total=total_frames or None)
                ):
                    if index == 0:
                        height, width = frame.shape[:2]
                        self.frame_size = (width, height)
                        if render_path:
                            writer = cv2.VideoWriter(
                                render_path, cv2.VideoWriter_fourcc(*"mp4v"), self.fps, self.frame_size
                            )
                    rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                    mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)
                    timestamp_ms = int(index / self.fps * 1000)
                    detection = landmarker.detect_for_video(mp_image, timestamp_ms)
                    frames.append(self.format_frame(index, timestamp_ms, detection))
                    if writer:
                        self.draw_landmarks(frame, detection)
                        writer.write(frame)
                    if on_progress and total_frames > 0:
                        percent = min(100, (index + 1) * 100 // total_frames)
                        if percent != last_percent:
                            last_percent = percent
                            on_progress(percent)
            if not frames:
                raise PermanentError("Video has no readable frame")
            if on_progress and last_percent < 100:
                on_progress(100)
            if render_path:
                log.info("Rendered video written to %s", render_path)
            return frames
        finally:
            cap.release()
            if writer:
                writer.release()

    def process(
        self,
        video_path: str,
        render_path: str | None = None,
        on_progress: Callable[[int], None] | None = None,
    ) -> Self:
        """Run the detection and expose the raw `analyses.result` payload in ``result``."""
        frames = self.landmark_video(video_path, render_path, on_progress)
        self.result = {
            "fps": self.fps,
            "width": self.frame_size[0],
            "height": self.frame_size[1],
            "frames": frames,
        }
        return self
