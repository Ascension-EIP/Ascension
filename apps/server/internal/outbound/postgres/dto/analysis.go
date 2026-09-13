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
	ID               uuid.UUID            `db:"id"`
	VideoID          uuid.UUID            `db:"video_id"`
	Status           model.AnalysisStatus `db:"status"`
	ResultJSON       *[]byte              `db:"result_json"`
	Advice           *string              `db:"advice"`
	Progress         int                  `db:"progress"`
	ProcessingTimeMS *int                 `db:"processing_time_ms"`
	CompletedAt      *time.Time           `db:"completed_at"`
	CreatedAt        time.Time            `db:"created_at"`
	UpdatedAt        time.Time            `db:"updated_at"`
}

func (a Analysis) ToAnalysis() model.Analysis {
	return model.Analysis{
		ID:               a.ID,
		VideoID:          a.VideoID,
		Status:           a.Status,
		ResultJSON:       a.ResultJSON,
		Advice:           a.Advice,
		Progress:         a.Progress,
		ProcessingTimeMS: a.ProcessingTimeMS,
		CompletedAt:      a.CompletedAt,
		CreatedAt:        a.CreatedAt,
		UpdatedAt:        a.UpdatedAt,
	}
}
