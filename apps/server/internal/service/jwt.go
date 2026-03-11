package service

import (
	"context"
	"time"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/setup/config"
	"github.com/golang-jwt/jwt/v5"
)

type JWTService struct {
	exp    time.Duration
	secret string
}

func NewJWTService(cfg config.JWTConfig) JWTService {
	return JWTService{
		exp:    cfg.Exp,
		secret: cfg.Secret,
	}
}

func (s *JWTService) CreateAccessToken(ctx context.Context, user *model.User) (string, error) {
	claims := jwt.MapClaims{
		"user_id": user.ID,
		"role":    user.Role,
		"exp":     time.Now().Add(s.exp).Unix(),
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(s.secret))
}
