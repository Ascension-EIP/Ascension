package service

import (
	"context"
	"time"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/setup/config"
	"github.com/google/uuid"
)

type sessionRepository interface {
	CreateSession(context.Context, *model.NewSession) (*model.Session, error)
	// GetUnexpiredSession(ctx context.Context, sessionID string) (*model.Session, error)
	// UpdateSession(ctx context.Context, session *model.Session) error
	// DeleteSessionByUserID(ctx context.Context, userID uint, id string) error
	// DeleteExpiredSessions(ctx context.Context) error
}

type SessionService struct {
	repo        sessionRepository
	exp         time.Duration
	rememberExp time.Duration
}

func NewSessionService(cfg config.SessionConfig, repo sessionRepository) SessionService {
	return SessionService{
		repo:        repo,
		exp:         cfg.Exp,
		rememberExp: cfg.RememberExp,
	}
}

func (s *SessionService) CreateRefreshToken(ctx context.Context, userID uuid.UUID, remember bool) (uuid.UUID, error) {
	session, err := s.repo.CreateSession(ctx, &model.NewSession{
		UserID:    userID,
		ExpiresAt: time.Now().Add(s.exp),
	})
	if err != nil {
		return uuid.UUID{}, err
	}

	return session.ID, nil
}
