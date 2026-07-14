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
	GetUserByUnexpiredSessionID(context.Context, uuid.UUID) (*model.User, error)
	// GetUnexpiredSession(ctx context.Context, sessionID string) (*model.Session, error)
	// UpdateSession(ctx context.Context, session *model.Session) error
	DeleteSessionByUserID(context.Context, uuid.UUID, uuid.UUID) error
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

func (s *SessionService) DeleteRefreshTokenByUserID(ctx context.Context, userID uuid.UUID, sessionID uuid.UUID) error {
	return s.repo.DeleteSessionByUserID(ctx, userID, sessionID)
}

func (s *SessionService) GetUserBySessionID(ctx context.Context, sessionID uuid.UUID) (*model.User, error) {
	return s.repo.GetUserByUnexpiredSessionID(ctx, sessionID)
}
