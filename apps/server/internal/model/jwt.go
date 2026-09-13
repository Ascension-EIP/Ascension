// @date 2026-03-11
// @file jwt.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package model

import (
	"github.com/golang-jwt/jwt/v5"
	"uuid"
)

type JWTClaims struct {
	UserID    uuid.UUID `json:"user_id"`
	UserName  UserName  `json:"user_name"`
	UserEmail UserEmail `json:"user_email"`
	UserRole  UserRole  `json:"user_role"`
	jwt.RegisteredClaims
}
