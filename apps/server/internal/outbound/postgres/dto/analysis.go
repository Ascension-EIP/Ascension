package dto

import (
	"time"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/google/uuid"
)

type Analysis struct {
	ID               uuid.UUID  `db:"id"`
	VideoID          uuid.UUID  `db:"video_id"`
	Status           string     `db:"status"`
	ResultJSON       *[]byte    `db:"result_json"`
	ProcessingTimeMS *int       `db:"processing_time_ms"`
	CompletedAt      *time.Time `db:"completed_at"`
	CreatedAt        time.Time  `db:"created_at"`
	UpdatedAt        time.Time  `db:"updated_at"`
}

func (a *Analysis) ToAnalysis() *model.Analysis {
	return &model.Analysis{
		ID:               a.ID,
		VideoID:          a.VideoID,
		Status:           model.AnalysisStatus(a.Status),
		ResultJSON:       a.ResultJSON,
		ProcessingTimeMS: a.ProcessingTimeMS,
		CompletedAt:      a.CompletedAt,
		CreatedAt:        a.CreatedAt,
		UpdatedAt:        a.UpdatedAt,
	}
}
