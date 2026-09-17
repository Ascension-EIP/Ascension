# @date 2026-09-11
# @file video_body_skeleton.py
# @brief File description.
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
from typing import Self
from pathlib import Path

import cv2
import mediapipe as mp
from mediapipe.tasks.python import vision
from mediapipe.tasks.python.vision import drawing_styles, drawing_utils
from rich.progress import track

from common.utils.logger import log


class PoseSkeleton:
    def __init__(
        self, model: str = "resources/pose_landmarker_full.task"
    ):
        self.model = model
        self.video_path: str | None = None
        self.landmarker = self.init_model()
        self.mp_images_with_results: list[tuple] | None = None

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

    def landmark_video(self, video_path: str, landmarker):
        log.info("Landmarking the video frame per frame.")
        cv_video = cv2.VideoCapture(video_path)
        self.fps = cv_video.get(cv2.CAP_PROP_FPS)
        self.frame_size = (
            int(cv_video.get(cv2.CAP_PROP_FRAME_WIDTH)),
            int(cv_video.get(cv2.CAP_PROP_FRAME_HEIGHT)),
        )
        total_frames = int(cv_video.get(cv2.CAP_PROP_FRAME_COUNT))
        images_with_landmarks: list[tuple] = []

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
            images_with_landmarks.append((mp_image, pose_landmarker_result))

        cv_video.release()
        return images_with_landmarks



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
            self.mp_images_with_results, description="Rendering video..."
        ):
            writer.write(self.draw_landmarks_on_image(mp_image, detection_result))

        writer.release()
        log.info(f"Rendered video written to {output_path}")
        return output_path

    def process(self, video_path: str) -> Self:
        self.video_path = video_path
        self.mp_images_with_results = self.landmark_video(
            self.video_path, self.landmarker
        )
