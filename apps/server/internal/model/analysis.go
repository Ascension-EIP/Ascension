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
	ID               uuid.UUID
	VideoID          uuid.UUID
	Status           AnalysisStatus
	ResultJSON       *[]byte
	ProcessingTimeMS *int
	CompletedAt      *time.Time
	CreatedAt        time.Time
	UpdatedAt        time.Time
}
