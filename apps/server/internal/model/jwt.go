// @date 2026-09-20
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
	UserID        uuid.UUID    `json:"user_id"`
	UserUsername  UserUsername `json:"user_username"`
	UserFirstName string       `json:"user_first_name"`
	UserLastName  string       `json:"user_last_name"`
	UserEmail     UserEmail    `json:"user_email"`
	UserRole      UserRole     `json:"user_role"`
	jwt.RegisteredClaims
}
