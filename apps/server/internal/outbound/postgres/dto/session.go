// @date 2026-09-20
// @file session.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package dto

import (
	"net/netip"
	"time"

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
)

type Session struct {
	ID         uuid.UUID   `db:"id"`
	UserID     uuid.UUID   `db:"user_id"`
	TokenHash  string      `db:"token_hash"`
	UserAgent  *string     `db:"user_agent"`
	IPAddress  *netip.Addr `db:"ip_address"`
	LastUsedAt time.Time   `db:"last_used_at"`
	RevokedAt  *time.Time  `db:"revoked_at"`
	ExpiresAt  time.Time   `db:"expires_at"`
	CreatedAt  time.Time   `db:"created_at"`
}

func (v Session) ToSession() model.Session {
	return model.Session{
		ID:         v.ID,
		UserID:     v.UserID,
		TokenHash:  v.TokenHash,
		UserAgent:  v.UserAgent,
		IPAddress:  v.IPAddress,
		LastUsedAt: v.LastUsedAt,
		RevokedAt:  v.RevokedAt,
		ExpiresAt:  v.ExpiresAt,
		CreatedAt:  v.CreatedAt,
	}
}
