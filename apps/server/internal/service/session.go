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
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"time"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/setup/config"
	"github.com/google/uuid"
)

type sessionRepository interface {
	CreateSession(context.Context, *model.NewSession) (*model.Session, error)
	GetUserByValidSessionTokenHash(context.Context, string) (*model.User, error)
	// GetUnexpiredSession(ctx context.Context, sessionID string) (*model.Session, error)
	// UpdateSession(ctx context.Context, session *model.Session) error
	DeleteSessionByUserID(context.Context, uuid.UUID, string) error
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

// CreateRefreshToken returns a new random refresh token. Only its SHA-256 hash is stored.
func (s *SessionService) CreateRefreshToken(ctx context.Context, userID uuid.UUID, remember bool) (string, error) {
	raw := make([]byte, 32)
	if _, err := rand.Read(raw); err != nil {
		return "", err
	}
	token := base64.RawURLEncoding.EncodeToString(raw)

	if _, err := s.repo.CreateSession(ctx, &model.NewSession{
		UserID:    userID,
		TokenHash: hashRefreshToken(token),
		ExpiresAt: time.Now().Add(s.exp),
	}); err != nil {
		return "", err
	}

	return token, nil
}

func (s *SessionService) DeleteRefreshTokenByUserID(ctx context.Context, userID uuid.UUID, refreshToken string) error {
	return s.repo.DeleteSessionByUserID(ctx, userID, hashRefreshToken(refreshToken))
}

func (s *SessionService) GetUserByRefreshToken(ctx context.Context, refreshToken string) (*model.User, error) {
	return s.repo.GetUserByValidSessionTokenHash(ctx, hashRefreshToken(refreshToken))
}

func hashRefreshToken(token string) string {
	sum := sha256.Sum256([]byte(token))
	return hex.EncodeToString(sum[:])
}
