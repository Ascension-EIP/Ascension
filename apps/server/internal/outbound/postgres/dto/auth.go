// @date 2026-03-14
// @file auth.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package dto

import (
	"time"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/google/uuid"
)

type Session struct {
	ID        uuid.UUID `db:"id"`
	UserID    uuid.UUID `db:"user_id"`
	ExpiresAt time.Time `db:"expires_at"`
	CreatedAt time.Time `db:"created_at"`
}

func (v *Session) ToSession() *model.Session {
	return &model.Session{
		ID:        v.ID,
		UserID:    v.UserID,
		ExpiresAt: v.ExpiresAt,
		CreatedAt: v.CreatedAt,
	}
}
