// @date 2026-11-15
// @file advice.go
// @brief File description.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>, DimitriLaPoudre <lou.pellegrino@epitech.eu>, Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package model

import (
	"time"

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/shared"
)

type Advice struct {
	ID               uuid.UUID // = video_id
	Status           JobStatus
	Progress         int16
	Result           *shared.Hints
	Error            *string
	ProcessingTimeMS *time.Duration
	StartedAt        *time.Time
	CompletedAt      *time.Time
	CreatedAt        time.Time
	UpdatedAt        time.Time
}

type AdviceFilter struct {
	ID     *uuid.UUID
	Status *JobStatus
}

type AdvicePartial struct {
	ID               uuid.UUID
	Status           *JobStatus
	Progress         *int16
	Result           **shared.Hints
	Error            **string
	ProcessingTimeMS **time.Duration
	StartedAt        **time.Time
	CompletedAt      **time.Time
	CreatedAt        *time.Time
	UpdatedAt        *time.Time
}
