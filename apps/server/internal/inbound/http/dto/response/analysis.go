// @date 2026-09-06
// @file analysis.go
// @brief Response DTOs for analysis endpoints.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>, Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package response

import (
	"encoding/json"
	"time"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/google/uuid"
)

type AnalysisResponse struct {
	ID     uuid.UUID            `json:"id"`
	Type   model.AnalysisType   `json:"type"`
	Status model.AnalysisStatus `json:"status"`
}

func AnalysisToResponse(analysis *model.Analysis) *AnalysisResponse {
	return &AnalysisResponse{
		ID:     analysis.ID,
		Type:   analysis.Type,
		Status: analysis.Status,
	}
}

type AnalysisInfoResponse struct {
	ID               uuid.UUID            `json:"id"`
	VideoID          uuid.UUID            `json:"video_id"`
	Type             model.AnalysisType   `json:"type"`
	Status           model.AnalysisStatus `json:"status"`
	Progress         int                  `json:"progress"`
	Result           *json.RawMessage     `json:"result,omitempty"`
	Hints            *json.RawMessage     `json:"hints,omitempty"`
	Error            *string              `json:"error,omitempty"`
	ProcessingTimeMs *int                 `json:"processing_time_ms,omitempty"`
	StartedAt        *time.Time           `json:"started_at,omitempty"`
	CompletedAt      *time.Time           `json:"completed_at,omitempty"`
	CreatedAt        time.Time            `json:"created_at"`
	UpdatedAt        time.Time            `json:"updated_at"`
}

func AnalysisInfoToResponse(analysis *model.Analysis) *AnalysisInfoResponse {
	var rawResult *json.RawMessage
	if analysis.Result != nil {
		raw := json.RawMessage(*analysis.Result)
		rawResult = &raw
	}
	var rawHints *json.RawMessage
	if analysis.Hints != nil {
		raw := json.RawMessage(*analysis.Hints)
		rawHints = &raw
	}
	return &AnalysisInfoResponse{
		ID:               analysis.ID,
		VideoID:          analysis.VideoID,
		Type:             analysis.Type,
		Status:           analysis.Status,
		Progress:         analysis.Progress,
		Result:           rawResult,
		Hints:            rawHints,
		Error:            analysis.Error,
		ProcessingTimeMs: analysis.ProcessingTimeMs,
		StartedAt:        analysis.StartedAt,
		CompletedAt:      analysis.CompletedAt,
		CreatedAt:        analysis.CreatedAt,
		UpdatedAt:        analysis.UpdatedAt,
	}
}
