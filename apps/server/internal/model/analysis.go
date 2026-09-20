// @date 2026-03-18
// @file analysis.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package model

import (
	"fmt"
	"time"

	"uuid"
)

type AnalysisType string

const (
	AnalysisType2D AnalysisType = "2d"
	AnalysisType3D AnalysisType = "3d"
)

func (t AnalysisType) Validate() error {
	switch t {
	case AnalysisType2D, AnalysisType3D:
		return nil
	default:
		return fmt.Errorf("unknown")
	}
}

type JobStatus string

const (
	JobStatusPending         JobStatus = "pending"
	JobStatusProcessing      JobStatus = "processing"
	JobStatusGeneratingHints JobStatus = "generating_hints"
	JobStatusCompleted       JobStatus = "completed"
	JobStatusFailed          JobStatus = "failed"
)

func (s JobStatus) Validate() error {
	switch s {
	case JobStatusPending, JobStatusProcessing, JobStatusGeneratingHints, JobStatusCompleted, JobStatusFailed:
		return nil
	default:
		return fmt.Errorf("unknown")
	}
}

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

func (c AnalysisConfig) Validate() error {
	if err := c.Type.Validate(); err != nil {
		return fmt.Errorf("type: %w", err)
	}

	if err := c.Visibility.Validate(); err != nil {
		return fmt.Errorf("visibility: %w", err)
	}

	return nil
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
