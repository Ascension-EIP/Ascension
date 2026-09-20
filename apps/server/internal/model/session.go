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
