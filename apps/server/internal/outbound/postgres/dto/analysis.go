// @date 2026-09-18
// @file analysis.go
// @brief Database transfer object for analyses.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>, Nicolas TORO <nicolas.toro@epitech.eu>, Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package dto

import (
	"time"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/google/uuid"
)

type Analysis struct {
	ID               uuid.UUID  `db:"id"`
	VideoID          uuid.UUID  `db:"video_id"`
	Type             string     `db:"type"`
	Status           string     `db:"status"`
	Progress         int        `db:"progress"`
	Result           *[]byte    `db:"result"`
	Hints            *[]byte    `db:"hints"`
	Error            *string    `db:"error"`
	ProcessingTimeMs *int       `db:"processing_time_ms"`
	StartedAt        *time.Time `db:"started_at"`
	CompletedAt      *time.Time `db:"completed_at"`
	Visibility       string     `db:"visibility"`
	CreatedAt        time.Time  `db:"created_at"`
	UpdatedAt        time.Time  `db:"updated_at"`
}

func (a *Analysis) ToAnalysis() *model.Analysis {
	return &model.Analysis{
		ID:               a.ID,
		VideoID:          a.VideoID,
		Type:             model.AnalysisType(a.Type),
		Status:           model.AnalysisStatus(a.Status),
		Progress:         a.Progress,
		Result:           a.Result,
		Hints:            a.Hints,
		Error:            a.Error,
		ProcessingTimeMs: a.ProcessingTimeMs,
		StartedAt:        a.StartedAt,
		CompletedAt:      a.CompletedAt,
		Visibility:       a.Visibility,
		CreatedAt:        a.CreatedAt,
		UpdatedAt:        a.UpdatedAt,
	}
}
