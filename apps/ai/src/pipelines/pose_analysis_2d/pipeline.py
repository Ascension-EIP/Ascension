# @date 2026-09-07
# @file pipeline.py
# @brief MediaPipe 2D pose analysis pipeline.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""MediaPipe 2D Pose Analysis pipeline."""

import logging
import os
from typing import Any

import cv2
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision

from src.common.geometry import compute_joint_angle
from src.common.video import open_video, resize_frame_if_needed
from src.core.interfaces import AdviceCapability, BasePipeline
from src.core.models import ProgressCallback
from src.pipelines.pose_analysis_2d.advice import Advice2DGenerator
from src.pipelines.pose_analysis_2d.constants import LM

logger = logging.getLogger("ai-worker.pipeline.2d")


class PoseAnalysis2DPipeline(BasePipeline, AdviceCapability):
    """MediaPipe-based 2D pose analysis pipeline with advice generation."""

    def __init__(
        self,
        model_path: str | None = None,
        gemini_api_key: str | None = None,
        gemini_model: str = "gemini-3.1-flash-lite",
    ):
        base_dir = os.path.dirname(
            os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        )
        self.model_path = model_path or os.getenv(
            "MEDIAPIPE_MODEL_PATH", os.path.join(base_dir, "pose_landmarker.task")
        )
        self.advice_generator = Advice2DGenerator(
            api_key=gemini_api_key or os.getenv("GEMINI_API_KEY"),
            model_name=gemini_model,
        )

    @property
    def name(self) -> str:
        return "pose_analysis_2d"

    def _process_pose(self, landmarks_raw: Any) -> dict[str, Any]:
        """Extract landmarks and compute 2D joint angles."""
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

        def _try_angle(a: int, joint: int, b: int) -> None:
            sa, sj, sb = str(a), str(joint), str(b)
            if all(k in lm for k in (sa, sj, sb)):
                angles[sj] = compute_joint_angle(lm[sa], lm[sj], lm[sb])

        # Elbows
        _try_angle(LM.L_SHOULDER, LM.L_ELBOW, LM.L_WRIST)
        _try_angle(LM.R_SHOULDER, LM.R_ELBOW, LM.R_WRIST)
        # Shoulders
        _try_angle(LM.L_ELBOW, LM.L_SHOULDER, LM.L_HIP)
        _try_angle(LM.R_ELBOW, LM.R_SHOULDER, LM.R_HIP)
        # Hips
        _try_angle(LM.L_SHOULDER, LM.L_HIP, LM.L_KNEE)
        _try_angle(LM.R_SHOULDER, LM.R_HIP, LM.R_KNEE)
        # Knees
        _try_angle(LM.L_HIP, LM.L_KNEE, LM.L_ANKLE)
        _try_angle(LM.R_HIP, LM.R_KNEE, LM.R_ANKLE)

        return {"landmarks": lm, "angles": angles}

    def analyze(
        self,
        video_path: str,
        on_progress: ProgressCallback | None = None,
        target_fps: int = 30,
        max_width: int = 640,
        **kwargs: Any,
    ) -> dict[str, Any]:
        """Analyze video using MediaPipe PoseLandmarker."""
        cap = open_video(video_path)
        fps = cap.get(cv2.CAP_PROP_FPS) or 30.0
        n_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))

        frame_step = max(1, int(round(fps / target_fps)))
        effective_frames = (n_frames + frame_step - 1) // frame_step

        logger.info(
            "Video: %d frames @ %.1f FPS — step %d (%d effective frames, max %dpx)",
            n_frames,
            fps,
            frame_step,
            effective_frames,
            max_width,
        )

        base_options = python.BaseOptions(model_asset_path=self.model_path)
        options = vision.PoseLandmarkerOptions(
            base_options=base_options,
            running_mode=vision.RunningMode.VIDEO,
        )

        try:
            with vision.PoseLandmarker.create_from_options(options) as landmarker:
                frames_list = []
                analyzed = 0
                i = 0

                while True:
                    ret, frame = cap.read()
                    if not ret:
                        break

                    if i % frame_step != 0:
                        i += 1
                        continue

                    frame, _ = resize_frame_if_needed(frame, max_width)
                    rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                    del frame

                    mp_image = mp.Image(
                        image_format=mp.ImageFormat.SRGB, data=rgb_frame
                    )
                    del rgb_frame

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
                        frame_data.update(self._process_pose(result.pose_landmarks[0]))

                    frames_list.append(frame_data)
                    analyzed += 1

                    if analyzed % 30 == 0:
                        if on_progress is not None and effective_frames > 0:
                            pct = min(99, int(analyzed / effective_frames * 100))
                            try:
                                on_progress(pct)
                            except Exception as err:
                                logger.warning("on_progress callback raised: %s", err)

                    i += 1

                logger.info("MediaPipe 2D analysis completed: %d frames analyzed", analyzed)
                return {"frames": frames_list}
        finally:
            cap.release()

    def generate_advice(self, analysis_result: dict[str, Any]) -> str | None:
        """Generate 2D-specific coaching advice using Gemini."""
        return self.advice_generator.generate(analysis_result)
