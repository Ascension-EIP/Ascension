# @date 2026-09-27
# @file pose_skeleton.py
# @brief File description.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
import math
from pathlib import Path
from typing import ClassVar, Self

import cv2
import mediapipe as mp
from mediapipe.tasks.python import vision
from mediapipe.tasks.python.components.containers.landmark import NormalizedLandmark
from mediapipe.tasks.python.vision import drawing_styles, drawing_utils
from rich.progress import track

from common.utils.logger import log

PoseLandmark = vision.PoseLandmark

#: Number of decimal places kept for coordinates/visibility.
COORD_PRECISION = 4
#: Number of decimal places kept for angles (in degrees).
ANGLE_PRECISION = 1


class PoseSkeleton:
    #: Angle at vertex ``B`` formed by the points ``A-B-C`` (MediaPipe convention).
    #: Names match the `body_zone` enum of the database schema.
    JOINTS: ClassVar[dict[str, tuple[PoseLandmark, PoseLandmark, PoseLandmark]]] = {
        "left_shoulder": (
            PoseLandmark.LEFT_ELBOW,
            PoseLandmark.LEFT_SHOULDER,
            PoseLandmark.LEFT_HIP,
        ),
        "right_shoulder": (
            PoseLandmark.RIGHT_ELBOW,
            PoseLandmark.RIGHT_SHOULDER,
            PoseLandmark.RIGHT_HIP,
        ),
        "left_elbow": (
            PoseLandmark.LEFT_SHOULDER,
            PoseLandmark.LEFT_ELBOW,
            PoseLandmark.LEFT_WRIST,
        ),
        "right_elbow": (
            PoseLandmark.RIGHT_SHOULDER,
            PoseLandmark.RIGHT_ELBOW,
            PoseLandmark.RIGHT_WRIST,
        ),
        "left_hip": (
            PoseLandmark.LEFT_SHOULDER,
            PoseLandmark.LEFT_HIP,
            PoseLandmark.LEFT_KNEE,
        ),
        "right_hip": (
            PoseLandmark.RIGHT_SHOULDER,
            PoseLandmark.RIGHT_HIP,
            PoseLandmark.RIGHT_KNEE,
        ),
        "left_knee": (
            PoseLandmark.LEFT_HIP,
            PoseLandmark.LEFT_KNEE,
            PoseLandmark.LEFT_ANKLE,
        ),
        "right_knee": (
            PoseLandmark.RIGHT_HIP,
            PoseLandmark.RIGHT_KNEE,
            PoseLandmark.RIGHT_ANKLE,
        ),
        "left_ankle": (
            PoseLandmark.LEFT_KNEE,
            PoseLandmark.LEFT_ANKLE,
            PoseLandmark.LEFT_FOOT_INDEX,
        ),
        "right_ankle": (
            PoseLandmark.RIGHT_KNEE,
            PoseLandmark.RIGHT_ANKLE,
            PoseLandmark.RIGHT_FOOT_INDEX,
        ),
    }

    def __init__(self, model: str = "resources/pose_landmarker_full.task"):
        self.model = model
        self.video_path: str | None = None
        self.landmarker = self.init_model()
        self.fps: float = 0.0
        self.frame_size: tuple[int, int] = (0, 0)
        #: Payload ready to be stored in `analyses.result`
        #: (``{"fps", "width", "height", "frames"}``).
        self.mp_images_with_results: dict | None = None
        #: Raw (image, MediaPipe result) pairs, kept for `render_video`.
        self.raw_frames: list[tuple] = []

    # def detect_frame(frame, detector):
    def init_model(self):
        log.info("Initializing the mediapipe model.")
        BaseOptions = mp.tasks.BaseOptions
        PoseLandmarker = mp.tasks.vision.PoseLandmarker
        PoseLandmarkerOptions = mp.tasks.vision.PoseLandmarkerOptions
        VisionRunningMode = mp.tasks.vision.RunningMode
        options = PoseLandmarkerOptions(
            base_options=BaseOptions(model_asset_path=self.model),
            running_mode=VisionRunningMode.VIDEO,
            min_pose_detection_confidence=0.1,
            min_pose_presence_confidence=0.1,
            min_tracking_confidence=0.1,
        )
        return PoseLandmarker.create_from_options(options)

    @staticmethod
    def coords(landmark: NormalizedLandmark) -> tuple[float, float, float]:
        """Coordinates (x, y, z) of the landmark, with ``None`` coerced to 0.0."""
        return (landmark.x or 0.0, landmark.y or 0.0, landmark.z or 0.0)

    @classmethod
    def angle(
        cls,
        a: NormalizedLandmark,
        b: NormalizedLandmark,
        c: NormalizedLandmark,
    ) -> float:
        """Angle in degrees at vertex ``b`` formed by the points ``a-b-c``."""
        ba = tuple(p - q for p, q in zip(cls.coords(a), cls.coords(b), strict=True))
        bc = tuple(p - q for p, q in zip(cls.coords(c), cls.coords(b), strict=True))
        norm = math.sqrt(sum(v * v for v in ba)) * math.sqrt(sum(v * v for v in bc))
        if norm == 0:
            raise ValueError("undefined angle: zero-length vector")
        cos = sum(p * q for p, q in zip(ba, bc, strict=True)) / norm
        return math.degrees(math.acos(max(-1.0, min(1.0, cos))))

    def format_landmarks(self, landmarks: list[NormalizedLandmark]) -> dict:
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

    def format_angles(self, landmarks: list[NormalizedLandmark]) -> dict:
        """Compute the usable joint angles for the frame."""
        angles: dict[str, float] = {}
        for name, (a, b, c) in self.JOINTS.items():
            if max(a, b, c) >= len(landmarks):
                continue
            try:
                angle = self.angle(landmarks[a], landmarks[b], landmarks[c])
            except ValueError:
                continue
            angles[name] = round(angle, ANGLE_PRECISION)
        return angles

    def format_frame(self, frame_index: int, timestamp_ms: int, result) -> dict:
        """Build a ``frames`` entry matching `analyses.result`."""
        poses = result.pose_landmarks
        landmarks = poses[0] if poses else []
        return {
            "frame": frame_index,
            "timestamp_ms": timestamp_ms,
            "pose_detected": bool(poses),
            "landmarks": self.format_landmarks(landmarks),
            "angles": self.format_angles(landmarks),
        }

    def landmark_video(self, video_path: str, landmarker) -> list[dict]:
        """Detect the skeleton frame by frame and return the formatted frames."""
        log.info("Landmarking the video frame per frame.")
        cv_video = cv2.VideoCapture(video_path)
        self.fps = cv_video.get(cv2.CAP_PROP_FPS) or 30.0
        self.frame_size = (
            int(cv_video.get(cv2.CAP_PROP_FRAME_WIDTH)),
            int(cv_video.get(cv2.CAP_PROP_FRAME_HEIGHT)),
        )
        total_frames = int(cv_video.get(cv2.CAP_PROP_FRAME_COUNT))
        self.raw_frames = []
        frames: list[dict] = []

        for frame_index in track(
            range(total_frames), description="Landmarking frames..."
        ):
            success, frame = cv_video.read()
            if not success:
                break
            rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb_frame)

            timestamp_ms = int(frame_index / self.fps * 1000)
            pose_landmarker_result = landmarker.detect_for_video(mp_image, timestamp_ms)
            self.raw_frames.append((mp_image, pose_landmarker_result))
            frames.append(
                self.format_frame(frame_index, timestamp_ms, pose_landmarker_result)
            )

        cv_video.release()
        return frames

    def draw_landmarks_on_image(self, mp_image, detection_result):
        pose_landmarks_list = detection_result.pose_landmarks
        annotated_image = cv2.cvtColor(mp_image.numpy_view(), cv2.COLOR_RGB2BGR)

        pose_landmark_style = drawing_styles.get_default_pose_landmarks_style()
        pose_connection_style = drawing_utils.DrawingSpec(
            color=(0, 255, 0), thickness=2
        )

        for pose_landmarks in pose_landmarks_list:
            drawing_utils.draw_landmarks(
                image=annotated_image,
                landmark_list=pose_landmarks,
                connections=vision.PoseLandmarksConnections.POSE_LANDMARKS,
                landmark_drawing_spec=pose_landmark_style,
                connection_drawing_spec=pose_connection_style,
            )

        return annotated_image

    def render_video(self) -> str:
        """Draw landmarks on every frame and write them to <video>-result.mp4."""
        output_path = str(
            Path(self.video_path).with_stem(Path(self.video_path).stem + "-result")
        )
        writer = cv2.VideoWriter(
            output_path, cv2.VideoWriter_fourcc(*"mp4v"), self.fps, self.frame_size
        )

        for mp_image, detection_result in track(
            self.raw_frames, description="Rendering video..."
        ):
            writer.write(self.draw_landmarks_on_image(mp_image, detection_result))

        writer.release()
        log.info(f"Rendered video written to {output_path}")
        return output_path

    def process(self, video_path: str) -> Self:
        """Run the detection and expose the full `analyses.result` payload."""
        self.video_path = video_path
        frames = self.landmark_video(self.video_path, self.landmarker)
        self.mp_images_with_results = {
            "fps": self.fps,
            "width": self.frame_size[0],
            "height": self.frame_size[1],
            "frames": frames,
        }
        return self
