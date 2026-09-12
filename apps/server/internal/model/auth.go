// @date 2026-03-19
// @file auth.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package model

import (
	"time"

	"uuid"
)

type SignupForm struct {
	Name     string
	Email    string
	Password []byte
}

type LoginForm struct {
	Email    string
	Password []byte
}

type Tokens struct {
	RefreshToken
	AccessToken
}

type RefreshToken struct {
	SessionToken string
}

type AccessToken struct {
	Token     string
	TokenType string
	ExpiresIn uint
}

type Session struct {
	ID        uuid.UUID
	UserID    uuid.UUID
	Token     string
	ExpiresAt time.Time
	CreatedAt time.Time
}
