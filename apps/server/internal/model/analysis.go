package model

import (
	"time"

	"github.com/google/uuid"
)

type AnalysisStatus string

const (
	AnalysisStatusPending   AnalysisStatus = "pending"
	AnalysisStatusCompleted AnalysisStatus = "completed"
)

type NewAnalysis struct {
	VideoID uuid.UUID
}

type Analysis struct {
	ID                 uuid.UUID
	VideoID            uuid.UUID
	Status             AnalysisStatus
	Result_json        *[]byte
	Processing_time_ms *int
	Completed_at       *time.Time
	Created_at         time.Time
	Updated_at         time.Time
}
