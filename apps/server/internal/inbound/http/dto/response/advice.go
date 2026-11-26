// @date 2026-11-15
// @file advice.go
// @brief File description.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>, DimitriLaPoudre <lou.pellegrino@epitech.eu>, Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package response

import (
	"time"

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/shared"
)

type AdviceResponse struct {
	ID               uuid.UUID       `json:"id"`
	Status           model.JobStatus `json:"status"`
	Progress         int16           `json:"progress"`
	Result           *shared.Hints   `json:"result"`
	Error            *string         `json:"error"`
	ProcessingTimeMS *time.Duration  `json:"processing_time_ms"`
	StartedAt        *time.Time      `json:"started_at"`
	CompletedAt      *time.Time      `json:"completed_at"`
	CreatedAt        time.Time       `json:"created_at"`
	UpdatedAt        time.Time       `json:"updated_at"`
}

func AdviceToResponse(advice model.Advice) AdviceResponse {
	return AdviceResponse{
		ID:               advice.ID,
		Status:           advice.Status,
		Progress:         advice.Progress,
		Result:           advice.Result,
		Error:            advice.Error,
		ProcessingTimeMS: advice.ProcessingTimeMS,
		StartedAt:        advice.StartedAt,
		CompletedAt:      advice.CompletedAt,
		CreatedAt:        advice.CreatedAt,
		UpdatedAt:        advice.UpdatedAt,
	}
}
