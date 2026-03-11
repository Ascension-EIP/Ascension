package service

import (
	"context"
	"fmt"
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
	claims := model.JWTClaims{
		UserID:   user.ID,
		UserRole: user.Role,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(s.exp)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(s.secret))
}

func (s *JWTService) ValidateAccessToken(ctx context.Context, tokenStr string) (*model.JWTClaims, error) {
	token, err := jwt.ParseWithClaims(
		tokenStr,
		&model.JWTClaims{},
		func(token *jwt.Token) (any, error) {
			if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, fmt.Errorf("invalid jwt algorythm: %v", token.Header["alg"])
			}
			return []byte(s.secret), nil
		},
	)
	if err != nil {
		return nil, err
	}

	claims, ok := token.Claims.(*model.JWTClaims)
	if !ok || !token.Valid {
		return nil, fmt.Errorf("invalid token")
	}

	return claims, nil
}
