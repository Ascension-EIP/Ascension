// @date 2026-09-18
// @file auth.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>, Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package model

import (
	"time"

	"github.com/google/uuid"
)

type SignupForm struct {
	Username  string
	FirstName string
	LastName  string
	Email     string
	Password  []byte
}

type SignupLoginForm struct {
	Username  string
	FirstName string
	LastName  string
	Email     string
	Password  []byte
	Remember  bool
}

type LoginForm struct {
	Email    string
	Password []byte
	Remember bool
}

type Tokens struct {
	RefreshToken string
	AccessToken
}

type AccessToken struct {
	Token     string
	TokenType string
	ExpiresIn uint
}

type NewSession struct {
	UserID    uuid.UUID
	TokenHash string
	ExpiresAt time.Time
}

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
