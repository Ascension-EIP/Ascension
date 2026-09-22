// @date 2026-09-20
// @file session.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package model

import (
	"net/netip"
	"time"

	"uuid"
)

type Session struct {
	ID         uuid.UUID
	UserID     uuid.UUID
	TokenHash  string
	UserAgent  *string
	IPAddress  *netip.Addr
	LastUsedAt time.Time
	RevokedAt  *time.Time
	ExpiresAt  time.Time
	CreatedAt  time.Time
}
