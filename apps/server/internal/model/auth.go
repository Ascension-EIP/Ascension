package model

import (
	"time"

	"github.com/google/uuid"
)

type SignupForm struct {
	Name     string
	Email    string
	Password []byte
}

type LoginForm struct {
	Email    string
	Password []byte
	Remember bool
}

type Tokens struct {
	AccessToken  string
	RefreshToken uuid.UUID
}

type NewSession struct {
	UserID    uuid.UUID
	ExpiresAt time.Time
}

type Session struct {
	ID        uuid.UUID
	UserID    uuid.UUID
	ExpiresAt time.Time
	CreatedAt time.Time
	UpdatedAt time.Time
}
