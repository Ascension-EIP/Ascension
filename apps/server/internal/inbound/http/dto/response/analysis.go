// @date 2026-03-18
// @file analysis.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package response

import (
	"time"
	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
)

type AnalysisResponse struct {
	ID               uuid.UUID          `json:"id"`
	VideoID          uuid.UUID          `json:"video_id"`
	Type             model.AnalysisType `json:"type"`
	Status           model.JobStatus    `json:"status"`
	Visibility       model.Visibility   `json:"visibility"`
	Progress         int16              `json:"progress"`
	Result           *map[string]any    `json:"result"`
	Advice           *string            `json:"advice"`
	Error            *string            `json:"error"`
	ProcessingTimeMS *time.Duration     `json:"processing_time_ms"`
	StartedAt        *time.Time         `json:"started_at"`
	CompletedAt      *time.Time         `json:"completed_at"`
}

func AnalysisToResponse(analysis model.Analysis) AnalysisResponse {
	return AnalysisResponse{
		ID:               analysis.ID,
		VideoID:          analysis.VideoID,
		Type:             analysis.Type,
		Status:           analysis.Status,
		Visibility:       analysis.Visibility,
		Progress:         analysis.Progress,
		Result:           analysis.Result,
		Advice:           analysis.Advice,
		Error:            analysis.Error,
		ProcessingTimeMS: analysis.ProcessingTimeMS,
		StartedAt:        analysis.StartedAt,
		CompletedAt:      analysis.CompletedAt,
	}
}
