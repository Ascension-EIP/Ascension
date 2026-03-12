package service

import (
	"context"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

type authRepository interface {
	CreateUser(context.Context, *model.NewUser) (*model.User, error)
	GetUserByEmail(context.Context, string) (*model.User, error)
}

type AuthService struct {
	jwtS     *JWTService
	sessionS *SessionService
	repo     authRepository
}

func NewAuthService(jwtS *JWTService, sessionS *SessionService, repo authRepository) AuthService {
	return AuthService{
		jwtS:     jwtS,
		sessionS: sessionS,
		repo:     repo,
	}
}

func (s *AuthService) Signup(ctx context.Context, form *model.SignupForm) (*model.User, error) {
	hash, err := bcrypt.GenerateFromPassword([]byte(form.Password), bcrypt.DefaultCost)
	if err != nil {
		return nil, model.ErrUnknown
	}

	user, err := s.repo.CreateUser(ctx, &model.NewUser{
		Name:     form.Name,
		Email:    form.Email,
		Password: hash,
		Role:     model.UserRoleUser,
	})
	if err != nil {
		return nil, err
	}

	return user, nil
}

func (s *AuthService) Login(ctx context.Context, form *model.LoginForm) (*model.User, *model.Tokens, error) {
	user, err := s.repo.GetUserByEmail(ctx, form.Email)
	if err != nil {
		return nil, nil, err
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(form.Password)); err != nil {
		return nil, nil, model.ErrBadPassword
	}

	accessToken, err := s.jwtS.CreateAccessToken(ctx, user)
	if err != nil {
		return nil, nil, err
	}

	refreshToken, err := s.sessionS.CreateRefreshToken(ctx, user.ID, form.Remember)
	if err != nil {
		return nil, nil, err
	}

	return user, &model.Tokens{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
	}, nil
}

func (s *AuthService) Logout(ctx context.Context, userID uuid.UUID, sessionID uuid.UUID) error {
	if err := s.sessionS.DeleteRefreshTokenByUserID(ctx, userID, sessionID); err != nil {
		return err
	}
	return nil
}

func (s *AuthService) RefreshAccessToken(ctx context.Context, userID uuid.UUID, sessionID uuid.UUID) (*model.AccessToken, error) {
	user := &model.User{}

	accessToken, err := s.jwtS.CreateAccessToken(ctx, user)
	if err != nil {
		return nil, err
	}

	return &accessToken, nil
}
