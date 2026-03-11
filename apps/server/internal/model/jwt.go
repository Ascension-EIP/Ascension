package model

import (
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
)

type JWTClaims struct {
	UserID uuid.UUID `json:"user_id"`
	Role   UserRole  `json:"role"`
	jwt.RegisteredClaims
}
