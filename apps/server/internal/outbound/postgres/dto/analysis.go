// @date 2026-03-18
// @file analysis.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package dto

import (
	"time"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"uuid"
)

type Analysis struct {
	ID               uuid.UUID       `db:"id"`
	VideoID          uuid.UUID       `db:"video_id"`
	Status           model.JobStatus `db:"status"`
	Result           *map[string]any `db:"result"`
	Advice           *string         `db:"advice"`
	Progress         int16           `db:"progress"`
	ProcessingTimeMS *time.Duration  `db:"processing_time_ms"`
	CompletedAt      *time.Time      `db:"completed_at"`
	CreatedAt        time.Time       `db:"created_at"`
	UpdatedAt        time.Time       `db:"updated_at"`
}

func (a Analysis) ToAnalysis() model.Analysis {
	return model.Analysis{
		ID:               a.ID,
		VideoID:          a.VideoID,
		Status:           a.Status,
		Result:           a.Result,
		Advice:           a.Advice,
		Progress:         a.Progress,
		ProcessingTimeMS: a.ProcessingTimeMS,
		CompletedAt:      a.CompletedAt,
		CreatedAt:        a.CreatedAt,
		UpdatedAt:        a.UpdatedAt,
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
