package model

import (
	"time"

	"uuid"
)

type Session struct {
	ID         uuid.UUID
	UserID     uuid.UUID
	TokenHash  string
	UserAgent  *string
	IPAddress  *string
	LastUsedAt time.Time
	RevokedAt  *time.Time
	ExpiresAt  time.Time
	CreatedAt  time.Time
}
