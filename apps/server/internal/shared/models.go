package shared

import "time"

type AnalysisResult struct {
	FPS       float64    `json:"fps"`
	Frames    []Frame    `json:"frames"`
	Height    int64      `json:"height"`
	Metrics   *Metrics   `json:"metrics,omitempty"`
	Movements []Movement `json:"movements,omitempty"`
	Pauses    []Pause    `json:"pauses,omitempty"`
	Width     int64      `json:"width"`
}

type Frame struct {
	// Joint angles in degrees, keyed by joint name.
	Angles       map[string]float64 `json:"angles"`
	ArmExtension *Sides             `json:"arm_extension,omitempty"`
	Frame        int64              `json:"frame"`
	// Keyed by lowercase MediaPipe landmark name.
	Landmarks    map[string]Landmark `json:"landmarks"`
	PoseDetected bool                `json:"pose_detected"`
	// Limb speeds in torso lengths per second, keyed by limb joint.
	Speeds      map[string]float64 `json:"speeds,omitempty"`
	TimestampMS int64              `json:"timestamp_ms"`
}

// Per-side values; a side is omitted when it could not be measured.
type Sides struct {
	Left  *float64 `json:"left,omitempty"`
	Right *float64 `json:"right,omitempty"`
}

type Landmark struct {
	Visibility float64 `json:"visibility"`
	X          float64 `json:"x"`
	Y          float64 `json:"y"`
	Z          float64 `json:"z"`
}

type Metrics struct {
	AvgArmExtension   *Sides             `json:"avg_arm_extension,omitempty"`
	AvgSpeed          map[string]float64 `json:"avg_speed,omitempty"`
	BentArmRatio      *Sides             `json:"bent_arm_ratio,omitempty"`
	DurationMS        int64              `json:"duration_ms"`
	PoseDetectionRate float64            `json:"pose_detection_rate"`
}

type Movement struct {
	EndFrame   int64 `json:"end_frame"`
	EndMS      int64 `json:"end_ms"`
	Limb       Limb  `json:"limb"`
	StartFrame int64 `json:"start_frame"`
	StartMS    int64 `json:"start_ms"`
}

type Pause struct {
	EndFrame   int64 `json:"end_frame"`
	EndMS      int64 `json:"end_ms"`
	StartFrame int64 `json:"start_frame"`
	StartMS    int64 `json:"start_ms"`
}

type Hints struct {
	GeneratedAt time.Time `json:"generated_at"`
	Items       []Hint    `json:"items"`
	Model       string    `json:"model"`
	Summary     string    `json:"summary"`
}

type Hint struct {
	BodyZones   []BodyZone `json:"body_zones,omitempty"`
	Category    FocusArea  `json:"category"`
	Description string     `json:"description"`
	FrameEnd    *int64     `json:"frame_end"`
	FrameStart  *int64     `json:"frame_start"`
	Priority    int64      `json:"priority"`
	Title       string     `json:"title"`
}

type Job struct {
	JobID string `json:"job_id"`
}

type JobStatus struct {
	JobID   string  `json:"job_id"`
	Message *string `json:"message"`
	Status  Status  `json:"status"`
}

type PoseDetectRequest struct {
	JobID     string `json:"job_id"`
	ObjectKey string `json:"object_key"`
}

type Limb string

const (
	LimbLeftFoot  Limb = "left_foot"
	LimbLeftHand  Limb = "left_hand"
	LimbRightFoot Limb = "right_foot"
	LimbRightHand Limb = "right_hand"
)

type BodyZone string

const (
	BodyZoneLeftFoot  BodyZone = "left_foot"
	BodyZoneLeftHand  BodyZone = "left_hand"
	BodyZoneRightFoot BodyZone = "right_foot"
	BodyZoneRightHand BodyZone = "right_hand"
	Head              BodyZone = "head"
	LeftAnkle         BodyZone = "left_ankle"
	LeftElbow         BodyZone = "left_elbow"
	LeftFingers       BodyZone = "left_fingers"
	LeftForearm       BodyZone = "left_forearm"
	LeftHip           BodyZone = "left_hip"
	LeftKnee          BodyZone = "left_knee"
	LeftShin          BodyZone = "left_shin"
	LeftShoulder      BodyZone = "left_shoulder"
	LeftThigh         BodyZone = "left_thigh"
	LeftUpperArm      BodyZone = "left_upper_arm"
	LeftWrist         BodyZone = "left_wrist"
	LowerBack         BodyZone = "lower_back"
	Neck              BodyZone = "neck"
	RightAnkle        BodyZone = "right_ankle"
	RightElbow        BodyZone = "right_elbow"
	RightFingers      BodyZone = "right_fingers"
	RightForearm      BodyZone = "right_forearm"
	RightHip          BodyZone = "right_hip"
	RightKnee         BodyZone = "right_knee"
	RightShin         BodyZone = "right_shin"
	RightShoulder     BodyZone = "right_shoulder"
	RightThigh        BodyZone = "right_thigh"
	RightUpperArm     BodyZone = "right_upper_arm"
	RightWrist        BodyZone = "right_wrist"
	Torso             BodyZone = "torso"
)

type FocusArea string

const (
	Endurance   FocusArea = "endurance"
	Flexibility FocusArea = "flexibility"
	Mental      FocusArea = "mental"
	Strength    FocusArea = "strength"
	Technique   FocusArea = "technique"
)

type Status string

const (
	Failed  Status = "failed"
	Pending Status = "pending"
	Running Status = "running"
	Started Status = "started"
	Success Status = "success"
)

type RoutingKey string

const (
	PoseAdviceRequested RoutingKey = "pose.advice.requested"
	PoseAdviceStatus    RoutingKey = "pose.advice.status"
	PoseDetectCompleted RoutingKey = "pose.detect.completed"
	PoseDetectRequested RoutingKey = "pose.detect.requested"
	PoseDetectStatus    RoutingKey = "pose.detect.status"
)
