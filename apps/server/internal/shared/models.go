package shared

type Job struct {
	JobID string `json:"job_id"`
}

type JobStatus struct {
	JobID   string  `json:"job_id"`
	Message *string `json:"message"`
	Status  Status  `json:"status"`
}

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
