// @date 2026-11-13
// @file analysis.go
// @brief File description.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>, DimitriLaPoudre <lou.pellegrino@epitech.eu>, Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package model

import (
	"fmt"
	"time"

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/shared"
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

// Job statuses written by the AI worker, as in schemas/job_status.schema.json and the
// job_status database enum.
const (
	JobStatusPending JobStatus = "pending"
	JobStatusStarted JobStatus = "started"
	JobStatusRunning JobStatus = "running"
	JobStatusSuccess JobStatus = "success"
	JobStatusFailed  JobStatus = "failed"
)

func (s JobStatus) Validate() error {
	switch s {
	case JobStatusPending, JobStatusStarted, JobStatusRunning, JobStatusSuccess, JobStatusFailed:
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
	Result           *shared.AnalysisResult
	Advice           *string
	Error            *string
	ProcessingTimeMS *time.Duration
	StartedAt        *time.Time
	CompletedAt      *time.Time
	CreatedAt        time.Time
	UpdatedAt        time.Time
	Hints            *shared.Hints
}

// AnalysisSummary is the light view of an analysis used in lists: it leaves out the
// result, advice and error payloads. ClimbingSessionID is the session of its video.
type AnalysisSummary struct {
	ID                uuid.UUID
	VideoID           uuid.UUID
	ClimbingSessionID *uuid.UUID
	Type              AnalysisType
	Status            JobStatus
	Visibility        Visibility
	Progress          int16
	StartedAt         *time.Time
	CompletedAt       *time.Time
	CreatedAt         time.Time
}

// AnalysisSummaryPage is one page of a user's analyses.
type AnalysisSummaryPage struct {
	Analyses   []AnalysisSummary
	Total      int
	Pagination Pagination
}

type AnalysisFilter struct {
	ID      *uuid.UUID
	VideoID *uuid.UUID
	Type    *AnalysisType
	Status  *JobStatus
	Error   **string
}

type AnalysisPartial struct {
	ID               uuid.UUID
	Status           *JobStatus
	Visibility       *Visibility
	Progress         *int16
	Result           **shared.AnalysisResult
	Advice           **string
	Error            **string
	ProcessingTimeMS **time.Duration
	StartedAt        **time.Time
	CompletedAt      **time.Time
	CreatedAt        *time.Time
	UpdatedAt        *time.Time
	Hints            **shared.Hints
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
