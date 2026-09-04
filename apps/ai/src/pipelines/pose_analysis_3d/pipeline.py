# @date 2026-09-05
# @file pipeline.py
# @brief SAM 3D Body pose estimation pipeline.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""SAM 3D Body Pose Analysis pipeline."""

import logging
import os
from typing import Any

import cv2
import numpy as np

from src.common.geometry import compute_joint_angle
from src.common.video import open_video
from src.core.interfaces import AdviceCapability, BasePipeline
from src.core.models import ProgressCallback
from src.pipelines.pose_analysis_3d.advice import Advice3DGenerator
from src.pipelines.pose_analysis_3d.constants import ANGLE_DEFS, KP

logger = logging.getLogger("ai-worker.pipeline.3d")


class PoseAnalysis3DPipeline(BasePipeline, AdviceCapability):
    """SAM 3D Body pose estimation pipeline with 3D advice generation."""

    def __init__(
        self,
        checkpoint_path: str = "",
        mhr_path: str = "",
        detector_name: str = "",
        segmentor_name: str = "",
        fov_name: str = "",
        detector_path: str = "",
        segmentor_path: str = "",
        fov_path: str = "",
        gemini_api_key: str | None = None,
        gemini_model: str = "gemini-3.1-flash-lite",
    ):
        base_dir = os.path.dirname(
            os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        )
        self.checkpoint_path = checkpoint_path or os.environ.get(
            "SAM3D_CHECKPOINT_PATH",
            os.path.join(base_dir, "checkpoints/sam-3d-body-dinov3/model.ckpt"),
        )
        self.mhr_path = mhr_path or os.environ.get(
            "SAM3D_MHR_PATH",
            os.path.join(base_dir, "checkpoints/sam-3d-body-dinov3/assets/mhr_model.pt"),
        )
        self.detector_name = detector_name or os.environ.get("SAM3D_DETECTOR_NAME", "")
        self.segmentor_name = segmentor_name or os.environ.get("SAM3D_SEGMENTOR_NAME", "")
        self.fov_name = fov_name or os.environ.get("SAM3D_FOV_NAME", "")
        self.detector_path = detector_path or os.environ.get("SAM3D_DETECTOR_PATH", "")
        self.segmentor_path = segmentor_path or os.environ.get("SAM3D_SEGMENTOR_PATH", "")
        self.fov_path = fov_path or os.environ.get("SAM3D_FOV_PATH", "")

        self._estimator: Any = None
        self.advice_generator = Advice3DGenerator(
            api_key=gemini_api_key or os.getenv("GEMINI_API_KEY"),
            model_name=gemini_model,
        )

    @property
    def name(self) -> str:
        return "pose_analysis_3d"

    def _get_or_create_estimator(self) -> Any:
        """Lazy load the SAM 3D Body estimator."""
        if self._estimator is not None:
            return self._estimator

        try:
            import torch
            from sam_3d_body import load_sam_3d_body, SAM3DBodyEstimator
        except ImportError:
            logger.warning("sam_3d_body package not installed. Running in mock/fallback mode.")
            return None

        device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        logger.info("Loading SAM 3D Body from %s on %s...", self.checkpoint_path, device)
        model, model_cfg = load_sam_3d_body(
            self.checkpoint_path, device=device, mhr_path=self.mhr_path
        )

        human_detector = None
        human_segmentor = None
        fov_estimator = None

        if self.detector_name:
            from tools.build_detector import HumanDetector
            human_detector = HumanDetector(
                name=self.detector_name, device=device, path=self.detector_path
            )

        if self.segmentor_name and (
            (self.segmentor_name == "sam2" and len(self.segmentor_path))
            or self.segmentor_name != "sam2"
        ):
            from tools.build_sam import HumanSegmentor
            human_segmentor = HumanSegmentor(
                name=self.segmentor_name, device=device, path=self.segmentor_path
            )

        if self.fov_name:
            from tools.build_fov_estimator import FOVEstimator
            fov_estimator = FOVEstimator(
                name=self.fov_name, device=device, path=self.fov_path
            )

        self._estimator = SAM3DBodyEstimator(
            sam_3d_body_model=model,
            model_cfg=model_cfg,
            human_detector=human_detector,
            human_segmentor=human_segmentor,
            fov_estimator=fov_estimator,
        )
        logger.info("SAM 3D Body Estimator ready.")
        return self._estimator

    def _compute_angles(self, kpts_3d: np.ndarray) -> dict[str, float]:
        """Compute 3D joint angles."""
        angles = {}
        for name, a, joint, b in ANGLE_DEFS:
            if a < len(kpts_3d) and joint < len(kpts_3d) and b < len(kpts_3d):
                angles[name] = compute_joint_angle(kpts_3d[a], kpts_3d[joint], kpts_3d[b])
        return angles

    def _serialise_frame_outputs(self, outputs: list[dict[str, Any]]) -> list[dict[str, Any]]:
        """Convert SAM 3D outputs to JSON-serialisable structure."""
        people = []
        for person in outputs:
            kpts_2d = person["pred_keypoints_2d"]
            kpts_3d = person["pred_keypoints_3d"]
            bbox = person["bbox"]
            angles = self._compute_angles(kpts_3d)

            landmarks = {}
            for idx, name in KP.NAMES.items():
                if idx < len(kpts_2d):
                    landmarks[name] = {
                        "x": round(float(kpts_2d[idx][0]), 2),
                        "y": round(float(kpts_2d[idx][1]), 2),
                        "z": round(float(kpts_3d[idx][2]), 5) if idx < len(kpts_3d) else 0.0,
                    }

            people.append(
                {
                    "bbox": [round(float(x), 2) for x in bbox],
                    "landmarks": landmarks,
                    "keypoints_2d": [[round(float(x), 2) for x in kp] for kp in kpts_2d],
                    "keypoints_3d": [[round(float(x), 5) for x in kp] for kp in kpts_3d],
                    "focal_length": round(float(person.get("focal_length", 0.0)), 4),
                    "pred_cam_t": [round(float(x), 5) for x in person.get("pred_cam_t", [])],
                    "angles": angles,
                }
            )
        return people

    def analyze(
        self,
        video_path: str,
        on_progress: ProgressCallback | None = None,
        sample_every: int = 3,
        **kwargs: Any,
    ) -> dict[str, Any]:
        """Run SAM 3D Body inference on the given video."""
        cap = open_video(video_path)
        fps = cap.get(cv2.CAP_PROP_FPS) or 30.0
        n_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
        height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))

        logger.info(
            "SAM-3D: %d frames at %.1f FPS (%dx%d), subsampling every %d frames",
            n_frames,
            fps,
            width,
            height,
            sample_every,
        )

        estimator = self._get_or_create_estimator()
        output = {"fps": fps, "width": width, "height": height, "frames": []}
        last_people: list[dict[str, Any]] = []

        try:
            for i in range(n_frames):
                ret, frame_bgr = cap.read()
                if not ret:
                    break

                timestamp_ms = int((i / fps) * 1000)

                if i % sample_every == 0 and estimator is not None:
                    frame_rgb = cv2.cvtColor(frame_bgr, cv2.COLOR_BGR2RGB)
                    try:
                        outputs = estimator.process_one_image(frame_rgb)
                        last_people = self._serialise_frame_outputs(outputs)
                    except Exception as e:
                        logger.warning("SAM-3D frame %d failed: %s", i, e)
                        last_people = []

                output["frames"].append(
                    {
                        "frame": i,
                        "timestamp_ms": timestamp_ms,
                        "sampled": i % sample_every == 0,
                        "n_people": len(last_people),
                        "people": last_people,
                    }
                )

                if i % 30 == 0 and on_progress is not None and n_frames > 0:
                    pct = min(99, int((i + 1) / n_frames * 100))
                    try:
                        on_progress(pct)
                    except Exception as err:
                        logger.warning("on_progress callback raised: %s", err)

            logger.info("SAM 3D inference completed: %d frames processed", len(output["frames"]))
            return output
        finally:
            cap.release()

    def generate_advice(self, analysis_result: dict[str, Any]) -> str | None:
        """Generate 3D-specific coaching advice using Gemini."""
        return self.advice_generator.generate(analysis_result)
