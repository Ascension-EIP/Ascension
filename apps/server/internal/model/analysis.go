// @date 2026-03-18
// @file analysis.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package model

import (
	"time"

	"uuid"
)

type AnalysisType string

const (
	AnalysisType2D AnalysisType = "2D"
	AnalysisType3D AnalysisType = "3D"
)

type JobStatus string

const (
	JobStatusPending         JobStatus = "pending"
	JobStatusProcessing      JobStatus = "processing"
	JobStatusGeneratingHints JobStatus = "generating_hints"
	JobStatusCompleted       JobStatus = "completed"
	JobStatusFailed          JobStatus = "failed"
)

type Analysis struct {
	ID               uuid.UUID
	VideoID          uuid.UUID
	Type             AnalysisType
	Status           JobStatus
	Visibility       Visibility
	Progress         int16
	Result           *map[string]any
	Advice           *string
	Error            *string
	ProcessingTimeMS *time.Duration
	StartedAt        *time.Time
	CompletedAt      *time.Time
	CreatedAt        time.Time
	UpdatedAt        time.Time
}

type AnalysisFilter struct {
	ID      *uuid.UUID
	VideoID *uuid.UUID
	Type    *AnalysisType
	Status  *JobStatus
}

type AnalysisConfig struct {
	VideoID    uuid.UUID
	Type       AnalysisType
	Visibility Visibility
}

// type AnalysisScores struct {
// 	AnalysisID     uuid.UUID
// 	OverallScore   float64
// 	TechniqueScore float64
// 	PowerScore     float64
// 	EnduranceScore float64
// 	Details        *[]byte
// 	CreatedAt      time.Time
// }
