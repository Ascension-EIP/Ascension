package auth

import (
	"context"
	"errors"
	"time"

	"github.com/DimitriLaPoudre/go-backend-base/internal/entity"
	"github.com/DimitriLaPoudre/go-backend-base/internal/infra/config"
	"github.com/DimitriLaPoudre/go-backend-base/internal/repo"
	"golang.org/x/crypto/bcrypt"
)

type repository interface {
	CreateUser(ctx context.Context, user *entity.User) error
	GetUserByUsername(ctx context.Context, username string) (*entity.User, error)
	GetUnexpiredSession(ctx context.Context, sessionID string) (*entity.Session, error)
	CreateSession(ctx context.Context, session *entity.Session) error
	UpdateSession(ctx context.Context, session *entity.Session) error
	DeleteSessionByUserID(ctx context.Context, userID uint, id string) error
	DeleteExpiredSessions(ctx context.Context) error
}

type Service struct {
	repo repository
	cfg  config.AuthConfig
}

func New(cfg *config.Config, repo repository) *Service {
	return &Service{
		repo: repo,
		cfg:  cfg.Auth,
	}
}

func (s *Service) Signup(c context.Context, form *entity.AuthForm) error {
	if err := validateUsername(form.Username); err != nil {
		return err
	}
	if err := validatePassword(form.Password); err != nil {
		return err
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(form.Password), bcrypt.DefaultCost)
	if err != nil {
		return err
	}
	if err := s.repo.CreateUser(c, &entity.User{
		Username: form.Username,
		Password: string(hash),
	}); err != nil {
		switch {
		case errors.Is(err, repo.ErrDuplicatedKey):
			return entity.ErrUsernameExists
		default:
			return err
		}
	}
	return nil
}

func (s *Service) Login(c context.Context, form *entity.AuthForm) (*entity.Session, error) {
	user, err := s.repo.GetUserByUsername(c, form.Username)
	if err != nil {
		switch {
		case errors.Is(err, repo.ErrNotFound):
			return nil, entity.ErrInvalidUsername
		default:
			return nil, err
		}
	}
	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(form.Password)); err != nil {
		switch {
		case errors.Is(err, bcrypt.ErrMismatchedHashAndPassword):
			return nil, entity.ErrInvalidPassword
		default:
			return nil, err
		}
	}

	sessionID, err := newSessionID()
	if err != nil {
		return nil, err
	}
	session := &entity.Session{
		ID:        sessionID,
		UserID:    user.ID,
		ExpiresAt: time.Now().Add(s.cfg.CookieExp),
	}
	err = s.repo.CreateSession(c, session)
	if err != nil {
		return nil, err
	}
	return session, nil
}

func (s *Service) Logout(c context.Context, userID uint, sessionID string) error {
	if err := s.repo.DeleteSessionByUserID(c, userID, sessionID); err != nil {
		return err
	}
	return nil
}

func (s *Service) ValidateSession(c context.Context, sessionID string) (uint, error) {
	session, err := s.repo.GetUnexpiredSession(c, sessionID)
	if err != nil {
		return 0, entity.ErrUnauthorized
	}
	return session.UserID, nil
}

func (s *Service) RefreshSession(c context.Context, sessionID string) error {
	session := &entity.Session{
		ID:        sessionID,
		ExpiresAt: time.Now().Add(s.cfg.CookieExp),
	}
	if err := s.repo.UpdateSession(c, session); err != nil {
		return err
	}
	return nil
}

func (s *Service) CleanExpiredSession(c context.Context) error {
	if err := s.repo.DeleteExpiredSessions(c); err != nil {
		return err
	}
	return nil
}
