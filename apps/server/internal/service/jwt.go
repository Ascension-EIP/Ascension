// @date 2026-03-12
// @file jwt.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
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
	cfg config.JWTConfig
}

func NewJWTService(cfg config.JWTConfig) JWTService {
	return JWTService{
		cfg: cfg,
	}
}

func (s *JWTService) CreateAccessToken(ctx context.Context, user *model.User) (model.AccessToken, error) {
	claims := model.JWTClaims{
		UserID:    user.ID,
		UserRole:  user.Role,
		ExpiresAt: jwt.NewNumericDate(time.Now().Add(s.cfg.Exp)),
		IssuedAt:  jwt.NewNumericDate(time.Now()),
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenSigned, err := token.SignedString([]byte(s.cfg.Secret))
	if err != nil {
		return model.AccessToken{}, err
	}

	return model.AccessToken{
		Token:     tokenSigned,
		TokenType: "Bearer",
		ExpiresIn: uint(s.cfg.Exp.Seconds()),
	}, nil
}

func (s *JWTService) ValidateAccessToken(ctx context.Context, tokenStr string) (*model.JWTClaims, error) {
	token, err := jwt.ParseWithClaims(
		tokenStr,
		&model.JWTClaims{},
		func(token *jwt.Token) (any, error) {
			if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, fmt.Errorf("invalid jwt algorythm: %v", token.Header["alg"])
			}
			return []byte(s.cfg.Secret), nil
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
