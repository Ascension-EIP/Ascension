// @date 2026-09-06
// @file analysis.go
// @brief Domain models for analyses.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>, Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package model

import (
	"time"

	"github.com/google/uuid"
)

type AnalysisStatus string

const (
	AnalysisStatusPending   AnalysisStatus = "pending"
	AnalysisStatusCompleted AnalysisStatus = "completed"
	AnalysisStatusFailed    AnalysisStatus = "failed"
)

type AnalysisType string

const (
	AnalysisType2D AnalysisType = "2d"
	AnalysisType3D AnalysisType = "3d"
)

type NewAnalysis struct {
	VideoID uuid.UUID
	Type    AnalysisType
}

type Analysis struct {
	ID             uuid.UUID
	VideoID        uuid.UUID
	Type           AnalysisType
	Status         AnalysisStatus
	Progress       int
	Result         *[]byte
	Hints          *string
	Error          *string
	ProcessingTime *int
	CompletedAt    *time.Time
	CreatedAt      time.Time
	UpdatedAt      time.Time
}
