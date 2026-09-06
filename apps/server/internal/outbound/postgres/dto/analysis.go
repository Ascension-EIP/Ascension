// @date 2026-09-06
// @file analysis.go
// @brief Database transfer object for analyses.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>, Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package dto

import (
	"time"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/google/uuid"
)

type Analysis struct {
	ID             uuid.UUID  `db:"id"`
	VideoID        uuid.UUID  `db:"video_id"`
	Type           string     `db:"type"`
	Status         string     `db:"status"`
	Progress       int        `db:"progress"`
	Result         *[]byte    `db:"result"`
	Hints          *string    `db:"hints"`
	Error          *string    `db:"error"`
	ProcessingTime *int       `db:"processing_time"`
	CompletedAt    *time.Time `db:"completed_at"`
	CreatedAt      time.Time  `db:"created_at"`
	UpdatedAt      time.Time  `db:"updated_at"`
}

func (a *Analysis) ToAnalysis() *model.Analysis {
	return &model.Analysis{
		ID:             a.ID,
		VideoID:        a.VideoID,
		Type:           model.AnalysisType(a.Type),
		Status:         model.AnalysisStatus(a.Status),
		Progress:       a.Progress,
		Result:         a.Result,
		Hints:          a.Hints,
		Error:          a.Error,
		ProcessingTime: a.ProcessingTime,
		CompletedAt:    a.CompletedAt,
		CreatedAt:      a.CreatedAt,
		UpdatedAt:      a.UpdatedAt,
	}
}
