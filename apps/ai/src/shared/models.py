# @date 2026-11-01
# @file models.py
# @brief File description.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>, Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
from pydantic import BaseModel
from typing import Optional
from enum import StrEnum
from datetime import datetime


class Sides(BaseModel):
    """Per-side values; a side is omitted when it could not be measured."""

    left: Optional[float] = None
    right: Optional[float] = None


class Landmark(BaseModel):
    visibility: float
    x: float
    y: float
    z: float


class Frame(BaseModel):
    angles: dict[str, float]
    """Joint angles in degrees, keyed by joint name."""

    frame: int
    landmarks: dict[str, Landmark]
    """Keyed by lowercase MediaPipe landmark name."""

    pose_detected: bool
    timestamp_ms: int
    arm_extension: Optional[Sides] = None
    speeds: Optional[dict[str, float]] = None
    """Limb speeds in torso lengths per second, keyed by limb joint."""


class Metrics(BaseModel):
    duration_ms: int
    pose_detection_rate: float
    avg_arm_extension: Optional[Sides] = None
    avg_speed: Optional[dict[str, float]] = None
    bent_arm_ratio: Optional[Sides] = None


class Limb(StrEnum):
    LEFT_FOOT = "left_foot"
    LEFT_HAND = "left_hand"
    RIGHT_FOOT = "right_foot"
    RIGHT_HAND = "right_hand"


class Movement(BaseModel):
    end_frame: int
    end_ms: int
    limb: Limb
    start_frame: int
    start_ms: int


class Pause(BaseModel):
    end_frame: int
    end_ms: int
    start_frame: int
    start_ms: int


class AnalysisResult(BaseModel):
    fps: float
    frames: list[Frame]
    height: int
    width: int
    metrics: Optional[Metrics] = None
    movements: Optional[list[Movement]] = None
    pauses: Optional[list[Pause]] = None


class BodyZone(StrEnum):
    HEAD = "head"
    LEFT_ANKLE = "left_ankle"
    LEFT_ELBOW = "left_elbow"
    LEFT_FINGERS = "left_fingers"
    LEFT_FOOT = "left_foot"
    LEFT_FOREARM = "left_forearm"
    LEFT_HAND = "left_hand"
    LEFT_HIP = "left_hip"
    LEFT_KNEE = "left_knee"
    LEFT_SHIN = "left_shin"
    LEFT_SHOULDER = "left_shoulder"
    LEFT_THIGH = "left_thigh"
    LEFT_UPPER_ARM = "left_upper_arm"
    LEFT_WRIST = "left_wrist"
    LOWER_BACK = "lower_back"
    NECK = "neck"
    RIGHT_ANKLE = "right_ankle"
    RIGHT_ELBOW = "right_elbow"
    RIGHT_FINGERS = "right_fingers"
    RIGHT_FOOT = "right_foot"
    RIGHT_FOREARM = "right_forearm"
    RIGHT_HAND = "right_hand"
    RIGHT_HIP = "right_hip"
    RIGHT_KNEE = "right_knee"
    RIGHT_SHIN = "right_shin"
    RIGHT_SHOULDER = "right_shoulder"
    RIGHT_THIGH = "right_thigh"
    RIGHT_UPPER_ARM = "right_upper_arm"
    RIGHT_WRIST = "right_wrist"
    TORSO = "torso"


class FocusArea(StrEnum):
    ENDURANCE = "endurance"
    FLEXIBILITY = "flexibility"
    MENTAL = "mental"
    STRENGTH = "strength"
    TECHNIQUE = "technique"


class Hint(BaseModel):
    category: FocusArea
    description: str
    priority: int
    title: str
    body_zones: Optional[list[BodyZone]] = None
    frame_end: Optional[int] = None
    frame_start: Optional[int] = None


class Hints(BaseModel):
    generated_at: datetime
    items: list[Hint]
    model: str
    summary: str


class Job(BaseModel):
    job_id: str


class Status(StrEnum):
    FAILED = "failed"
    PENDING = "pending"
    RUNNING = "running"
    STARTED = "started"
    SUCCESS = "success"


class JobStatus(BaseModel):
    job_id: str
    status: Status
    message: Optional[str] = None


class PoseDetectRequest(BaseModel):
    job_id: str
    object_key: str


class RoutingKey(StrEnum):
    POSE_ADVICE_REQUESTED = "pose.advice.requested"
    POSE_ADVICE_STATUS = "pose.advice.status"
    POSE_DETECT_COMPLETED = "pose.detect.completed"
    POSE_DETECT_REQUESTED = "pose.detect.requested"
    POSE_DETECT_STATUS = "pose.detect.status"
