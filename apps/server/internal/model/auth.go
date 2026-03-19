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

type SignupLoginForm struct {
	Name     string
	Email    string
	Password []byte
	Remember bool
}

type LoginForm struct {
	Email    string
	Password []byte
	Remember bool
}

type Tokens struct {
	RefreshToken uuid.UUID
	AccessToken
}

type AccessToken struct {
	Token     string
	TokenType string
	ExpiresIn uint
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
}
