// @date 2026-09-20
// @file analysis.go
// @brief File description.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>, Christophe Vandevoir <christophe.vandevoir@epitech.eu>, DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package dto

import (
	"time"

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/shared"
)

type Analysis struct {
	ID               uuid.UUID          `db:"id"`
	VideoID          uuid.UUID          `db:"video_id"`
	Type             model.AnalysisType `db:"type"`
	Status           model.JobStatus    `db:"status"`
	Visibility       model.Visibility   `db:"visibility"`
	Result           *map[string]any    `db:"result"`
	Advice           *string            `db:"advice"`
	Error            *string            `db:"error"`
	Progress         int16              `db:"progress"`
	ProcessingTimeMS *time.Duration     `db:"processing_time_ms"`
	StartedAt        *time.Time         `db:"started_at"`
	CompletedAt      *time.Time         `db:"completed_at"`
	CreatedAt        time.Time          `db:"created_at"`
	UpdatedAt        time.Time          `db:"updated_at"`
	Hints            *shared.Hints      `db:"hints"`
}

func (a Analysis) ToAnalysis() model.Analysis {
	return model.Analysis{
		ID:               a.ID,
		VideoID:          a.VideoID,
		Type:             a.Type,
		Status:           a.Status,
		Visibility:       a.Visibility,
		Progress:         a.Progress,
		Result:           a.Result,
		Advice:           a.Advice,
		ProcessingTimeMS: a.ProcessingTimeMS,
		StartedAt:        a.StartedAt,
		CompletedAt:      a.CompletedAt,
		CreatedAt:        a.CreatedAt,
		UpdatedAt:        a.UpdatedAt,
		Hints:            a.Hints,
	}
}

// type AnalysisScores struct {
// 	AnalysisID     uuid.UUID   `db:"analysis_id"`
// 	OverallScore   float64     `db:"overall_score"`
// 	TechniqueScore float64     `db:"technique_score"`
// 	PowerScore     float64     `db:"power_score"`
// 	EnduranceScore float64     `db:"endurance_score"`
// 	Details        *[]byte     `db:"details"`
// 	CreatedAt      time.Time   `db:"created_at"`
// }
//
// func (a AnalysisScores) ToAnalysisScores() model.AnalysisScores {
// 	return model.AnalysisScores{
// 		AnalysisID:     a.AnalysisID,
// 		OverallScore:   a.OverallScore,
// 		TechniqueScore: a.TechniqueScore,
// 		PowerScore:     a.PowerScore,
// 		EnduranceScore: a.EnduranceScore,
// 		Details:        a.Details,
// 		CreatedAt:      a.CreatedAt,
// 	}
// }
