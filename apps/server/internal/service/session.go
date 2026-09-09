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
	"time"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/setup/config"
	"uuid"
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

func (s *SessionService) CreateRefreshToken(ctx context.Context, userID uuid.UUID, remember bool) (uuid.UUID, error) {
	session, err := s.repo.CreateSession(ctx, &model.NewSession{
		UserID:    userID,
		ExpiresAt: time.Now().Add(s.cfg.Exp),
	})
	if err != nil {
		return uuid.UUID{}, err
	}

	return session.ID, nil
}

func (s *SessionService) DeleteRefreshTokenByUserID(ctx context.Context, userID uuid.UUID, sessionID uuid.UUID) error {
	return s.repo.DeleteSessionByUserID(ctx, userID, sessionID)
}

func (s *SessionService) GetUserBySessionID(ctx context.Context, sessionID uuid.UUID) (*model.User, error) {
	return s.repo.GetUserByUnexpiredSessionID(ctx, sessionID)
}
