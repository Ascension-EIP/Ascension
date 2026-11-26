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


class BetaPreference(StrEnum):
    """Style of the beta: easy (easiest), power (fewer and longer moves), technique (short
    moves, more foot placements). The worker defaults to easy.
    """
    EASY = "easy"
    POWER = "power"
    TECHNIQUE = "technique"


class GhostComputeRequest(BaseModel):
    """Payload of ghosts.compute.requested: compute the ghost of a route. job_id is ghosts.id."""

    job_id: str
    preference: Optional[BetaPreference] = None


class ConstraintType(StrEnum):
    INJURED = "injured"
    MISSING = "missing"


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


class BodyConstraint(BaseModel):
    type: ConstraintType
    zone: BodyZone


class DominantHand(StrEnum):
    AMBIDEXTROUS = "ambidextrous"
    LEFT = "left"
    RIGHT = "right"


class GhostMorphology(BaseModel):
    """Format of ghosts.morphology."""

    height_cm: float
    arm_span_cm: Optional[float] = None
    """Defaults to height_cm."""

    constraints: Optional[list[BodyConstraint]] = None
    dominant_hand: Optional[DominantHand] = None


class GhostPoint(BaseModel):
    x: float
    y: float


class GhostHolds(BaseModel):
    """Hold id under each limb, null when the limb is free."""

    left_foot: Optional[str] = None
    left_hand: Optional[str] = None
    right_foot: Optional[str] = None
    right_hand: Optional[str] = None


class GhostStep(BaseModel):
    """One pose of the ghost. moved_limb is the limb moved to reach it, absent for the start
    step.
    """
    center_of_mass: GhostPoint
    holds: GhostHolds
    index: int
    landmarks: dict[str, GhostPoint]
    moved_limb: Optional[Limb] = None


class GhostPath(BaseModel):
    """Format of ghosts.path. Coordinates are pixels of the route photo (y down); landmark names
    are the keys of Frame.landmarks.
    """
    image_height: int
    image_width: int
    steps: list[GhostStep]
    wall_angle_deg: Optional[float] = None


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


class HoldDetectRequest(BaseModel):
    """Payload of holds.detect.requested: detect the holds of a route photo. job_id is routes.id."""

    job_id: str
    object_key: str
    gravity: Optional[list[float]] = None
    """Direction of the ground in the camera frame of the photo (OpenCV axes: x right, y down, z
    forward), any norm; sent by the mobile from the accelerometer.
    """


class HoldColor(BaseModel):
    """Dominant colour of the hold. rgb is reliable for display; name is the closest reference
    colour and is less reliable (distance: lower is closer).
    """
    distance: float
    name: str
    rgb: list[int]


class HoldBox(BaseModel):
    h: float
    w: float
    x: float
    y: float


class HoldPoint(BaseModel):
    x: float
    y: float


class HoldContour(BaseModel):
    """Same format as holds.contour: polygon of the hold and its bounding box."""

    bbox: HoldBox
    points: list[HoldPoint]


class HoldType(StrEnum):
    """Values of the hold_type enum of the database. The detector only returns unknown (any
    hold) and volume.
    """
    CRIMP = "crimp"
    EDGE = "edge"
    FOOTHOLD = "foothold"
    JUG = "jug"
    PINCH = "pinch"
    POCKET = "pocket"
    SLOPER = "sloper"
    UNKNOWN = "unknown"
    VOLUME = "volume"


class DetectedHold(BaseModel):
    confidence: float
    contour: HoldContour
    type: HoldType
    color: Optional[HoldColor] = None


class WallPlane(BaseModel):
    """Plane of the wall estimated from the photo. homography maps photo pixels to centimetres
    in the wall plane (y up).
    """
    focal_px: float
    homography: list[list[float]]
    inlier_ratio: float
    model: str
    """Name of the depth model."""

    angle_deg: Optional[float] = None
    """Wall angle: 0 vertical, > 0 overhang, < 0 slab; null when the gravity is unknown."""


class HoldDetectResult(BaseModel):
    """Holds detected on a route photo. Coordinates are pixels of the original photo
    (image_width x image_height). The worker stores each hold as one row of the holds table.
    """
    holds: list[DetectedHold]
    image_height: int
    image_width: int
    wall: Optional[WallPlane] = None


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
    GHOSTS_COMPUTE_REQUESTED = "ghosts.compute.requested"
    GHOSTS_COMPUTE_STATUS = "ghosts.compute.status"
    HOLDS_DETECT_REQUESTED = "holds.detect.requested"
    HOLDS_DETECT_STATUS = "holds.detect.status"
    POSE_ADVICE_REQUESTED = "pose.advice.requested"
    POSE_ADVICE_STATUS = "pose.advice.status"
    POSE_DETECT_COMPLETED = "pose.detect.completed"
    POSE_DETECT_REQUESTED = "pose.detect.requested"
    POSE_DETECT_STATUS = "pose.detect.status"
