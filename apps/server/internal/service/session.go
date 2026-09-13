// @date 2026-03-12
// @file session.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package service

import (
	"context"
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"time"

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/setup/config"
)

type SessionService struct {
	cfg  config.SessionConfig
	repo model.SessionRepository
}

func NewSessionService(cfg config.SessionConfig, repo model.SessionRepository) SessionService {
	return SessionService{
		cfg:  cfg,
		repo: repo,
	}
}

func (s *SessionService) GenerateSessionToken() (string, error) {
	b := make([]byte, 32)
	_, err := rand.Read(b)
	if err != nil {
		return "", fmt.Errorf("session token generation: %w", err)
	}
	return hex.EncodeToString(b), nil
}

func (s *SessionService) hashSessionToken(token string) (string, error) {
	mac := hmac.New(sha256.New, []byte(s.cfg.Secret))
	if _, err := mac.Write([]byte(token)); err != nil {
		return "", err
	}
	sum := mac.Sum(nil)
	return hex.EncodeToString(sum), nil
}

func (s *SessionService) CreateRefreshToken(ctx context.Context, userID uuid.UUID, remember bool) (model.RefreshToken, error) {
	token, err := s.GenerateSessionToken()
	if err != nil {
		return model.RefreshToken{}, fmt.Errorf("create token for new session: %w", err)
	}

	hashedToken, err := s.hashSessionToken(token)
	if err != nil {
		return model.RefreshToken{}, fmt.Errorf("hash token for new session: %w", err)
	}

	var expiresAt time.Time
	if remember {
		expiresAt = time.Now().Add(s.cfg.RememberExp)
	} else {
		expiresAt = time.Now().Add(s.cfg.Exp)
	}

	_, err = s.repo.CreateSession(ctx, model.Session{
		UserID:    userID,
		Token:     hashedToken,
		ExpiresAt: expiresAt,
	})
	if err != nil {
		return model.RefreshToken{}, fmt.Errorf("create new session: %w", err)
	}

	return model.RefreshToken{
		SessionToken: token,
	}, nil
}

func (s *SessionService) DeleteSessionByTokenAndUserID(ctx context.Context, token string, userID uuid.UUID) error {
	hashedToken, err := s.hashSessionToken(token)
	if err != nil {
		return fmt.Errorf("hash token: %w", err)
	}

	if err := s.repo.DeleteSessionByTokenAndUserID(ctx, hashedToken, userID); err != nil {
		return fmt.Errorf("delete user %v session by token %v: %w", userID, token, err)
	}

	return nil
}

func (s *SessionService) GetUserByValidToken(ctx context.Context, token string) (model.User, error) {
	hashedToken, err := s.hashSessionToken(token)
	if err != nil {
		return model.User{}, fmt.Errorf("hash token: %w", err)
	}

	user, err := s.repo.GetUserByValidToken(ctx, hashedToken)
	if err != nil {
		return model.User{}, fmt.Errorf("get user by token %v: %w", token, err)
	}

	return user, nil
}
