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

// Format of ghosts.morphology: the climber body used by the pathfinding.
type ClimberMorphology struct {
	// Defaults to height_cm.
	ArmSpanCM    *float64         `json:"arm_span_cm,omitempty"`
	Constraints  []BodyConstraint `json:"constraints,omitempty"`
	DominantHand *DominantHand    `json:"dominant_hand,omitempty"`
	HeightCM     float64          `json:"height_cm"`
}

type BodyConstraint struct {
	Type ConstraintType `json:"type"`
	Zone BodyZone       `json:"zone"`
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

// Payload of holds.detect.requested: detect the holds of a route photo. job_id is routes.id.
type HoldDetectRequest struct {
	// Direction of the ground in the camera frame of the photo (OpenCV axes: x right, y down, z
	// forward), any norm; sent by the mobile from the accelerometer.
	Gravity   []float64 `json:"gravity,omitempty"`
	JobID     string    `json:"job_id"`
	ObjectKey string    `json:"object_key"`
}

// Holds detected on a route photo. Coordinates are pixels of the original photo
// (image_width x image_height). The worker stores each hold as one row of the holds table.
type HoldDetectResult struct {
	Holds       []DetectedHold `json:"holds"`
	ImageHeight int64          `json:"image_height"`
	ImageWidth  int64          `json:"image_width"`
	Wall        *WallPlane     `json:"wall,omitempty"`
}

type DetectedHold struct {
	Color      *HoldColor  `json:"color,omitempty"`
	Confidence float64     `json:"confidence"`
	Contour    HoldContour `json:"contour"`
	Type       HoldType    `json:"type"`
}

// Dominant colour of the hold. rgb is reliable for display; name is the closest reference
// colour and is less reliable (distance: lower is closer).
type HoldColor struct {
	Distance float64 `json:"distance"`
	Name     string  `json:"name"`
	RGB      []int64 `json:"rgb"`
}

// Same format as holds.contour: polygon of the hold and its bounding box.
type HoldContour struct {
	Bbox   HoldBox     `json:"bbox"`
	Points []HoldPoint `json:"points"`
}

type HoldBox struct {
	H float64 `json:"h"`
	W float64 `json:"w"`
	X float64 `json:"x"`
	Y float64 `json:"y"`
}

type HoldPoint struct {
	X float64 `json:"x"`
	Y float64 `json:"y"`
}

// Plane of the wall estimated from the photo. homography maps photo pixels to centimetres
// in the wall plane (y up).
type WallPlane struct {
	// Wall angle: 0 vertical, > 0 overhang, < 0 slab; null when the gravity is unknown.
	AngleDeg    *float64    `json:"angle_deg"`
	FocalPx     float64     `json:"focal_px"`
	Homography  [][]float64 `json:"homography"`
	InlierRatio float64     `json:"inlier_ratio"`
	// Name of the depth model.
	Model string `json:"model"`
}

type Job struct {
	JobID string `json:"job_id"`
}

type JobStatus struct {
	JobID   string  `json:"job_id"`
	Message *string `json:"message"`
	Status  Status  `json:"status"`
}

// Payload of pathfinding.compute.requested: compute the beta and the postures of a climber
// on a route. job_id is ghosts.id (the row that receives the result in ghosts.path).
type PathfindingComputeRequest struct {
	JobID      string          `json:"job_id"`
	Preference *BetaPreference `json:"preference,omitempty"`
}

// Result of the pathfinding, stored in ghosts.path. Coordinates are pixels of the route
// photo (y down); landmark names are the keys of Frame.landmarks.
type PathfindingResult struct {
	ImageHeight  int64             `json:"image_height"`
	ImageWidth   int64             `json:"image_width"`
	Steps        []PathfindingStep `json:"steps"`
	WallAngleDeg *float64          `json:"wall_angle_deg"`
}

// One pose of the climber along the beta. moved_limb is the limb moved to reach it, absent
// for the start step.
type PathfindingStep struct {
	CenterOfMass Point2D            `json:"center_of_mass"`
	Holds        StepHolds          `json:"holds"`
	Index        int64              `json:"index"`
	Landmarks    map[string]Point2D `json:"landmarks"`
	MovedLimb    *Limb              `json:"moved_limb,omitempty"`
}

type Point2D struct {
	X float64 `json:"x"`
	Y float64 `json:"y"`
}

// Hold id under each limb, null when the limb is free.
type StepHolds struct {
	LeftFoot  *string `json:"left_foot"`
	LeftHand  *string `json:"left_hand"`
	RightFoot *string `json:"right_foot"`
	RightHand *string `json:"right_hand"`
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

type ConstraintType string

const (
	Injured ConstraintType = "injured"
	Missing ConstraintType = "missing"
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

type DominantHand string

const (
	Ambidextrous DominantHand = "ambidextrous"
	Left         DominantHand = "left"
	Right        DominantHand = "right"
)

type FocusArea string

const (
	Endurance          FocusArea = "endurance"
	Flexibility        FocusArea = "flexibility"
	FocusAreaTechnique FocusArea = "technique"
	Mental             FocusArea = "mental"
	Strength           FocusArea = "strength"
)

// Values of the hold_type enum of the database. The detector only returns unknown (any
// hold) and volume.
type HoldType string

const (
	Crimp    HoldType = "crimp"
	Edge     HoldType = "edge"
	Foothold HoldType = "foothold"
	Jug      HoldType = "jug"
	Pinch    HoldType = "pinch"
	Pocket   HoldType = "pocket"
	Sloper   HoldType = "sloper"
	Unknown  HoldType = "unknown"
	Volume   HoldType = "volume"
)

type Status string

const (
	Failed  Status = "failed"
	Pending Status = "pending"
	Running Status = "running"
	Started Status = "started"
	Success Status = "success"
)

// Style of the beta: easy (easiest), power (fewer and longer moves), technique (short
// moves, more foot placements). The worker defaults to easy.
type BetaPreference string

const (
	BetaPreferenceTechnique BetaPreference = "technique"
	Easy                    BetaPreference = "easy"
	Power                   BetaPreference = "power"
)

type RoutingKey string

const (
	HoldsDetectRequested        RoutingKey = "holds.detect.requested"
	HoldsDetectStatus           RoutingKey = "holds.detect.status"
	PathfindingComputeRequested RoutingKey = "pathfinding.compute.requested"
	PathfindingComputeStatus    RoutingKey = "pathfinding.compute.status"
	PoseAdviceRequested         RoutingKey = "pose.advice.requested"
	PoseAdviceStatus            RoutingKey = "pose.advice.status"
	PoseDetectCompleted         RoutingKey = "pose.detect.completed"
	PoseDetectRequested         RoutingKey = "pose.detect.requested"
	PoseDetectStatus            RoutingKey = "pose.detect.status"
)
