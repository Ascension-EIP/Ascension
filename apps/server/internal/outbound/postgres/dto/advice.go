// @date 2026-11-15
// @file advice.go
// @brief File description.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>, DimitriLaPoudre <lou.pellegrino@epitech.eu>, Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package dto

import (
	"time"

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/shared"
)

type Advice struct {
	ID               uuid.UUID       `db:"id"`
	Status           model.JobStatus `db:"status"`
	Progress         int16           `db:"progress"`
	Result           *shared.Hints   `db:"result"`
	Error            *string         `db:"error"`
	ProcessingTimeMS *time.Duration  `db:"processing_time_ms"`
	StartedAt        *time.Time      `db:"started_at"`
	CompletedAt      *time.Time      `db:"completed_at"`
	CreatedAt        time.Time       `db:"created_at"`
	UpdatedAt        time.Time       `db:"updated_at"`
}

func (a Advice) ToAdvice() model.Advice {
	return model.Advice{
		ID:               a.ID,
		Status:           a.Status,
		Progress:         a.Progress,
		Result:           a.Result,
		Error:            a.Error,
		ProcessingTimeMS: a.ProcessingTimeMS,
		StartedAt:        a.StartedAt,
		CompletedAt:      a.CompletedAt,
		CreatedAt:        a.CreatedAt,
		UpdatedAt:        a.UpdatedAt,
	}
}

func AdvicesToAdvices(dtos []Advice) []model.Advice {
	list := []model.Advice{}
	for _, item := range dtos {
		list = append(list, item.ToAdvice())
	}

	return list
}
