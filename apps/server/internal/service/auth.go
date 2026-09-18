// @date 2026-03-19
// @file auth.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package service

import (
	"context"
	"fmt"

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"golang.org/x/crypto/bcrypt"
)

type AuthService struct {
	jwtS     *JWTService
	sessionS *SessionService
	userS    *UserService
}

func NewAuthService(jwtS *JWTService, sessionS *SessionService, userS *UserService) AuthService {
	return AuthService{
		jwtS:     jwtS,
		sessionS: sessionS,
		userS:    userS,
	}
}

func (s *AuthService) SignupAndLogin(ctx context.Context, form model.SignupForm, remember bool) (model.User, model.Tokens, error) {
	if err := form.IsValid(); err != nil {
		return model.User{}, model.Tokens{}, fmt.Errorf("form validation: %w", err)
	}

	user, err := s.userS.CreateUser(ctx, model.User{
		Name:     form.Name,
		Email:    form.Email,
		Password: form.Password,
		Role:     model.UserRoleUser,
	})
	if err != nil {
		return model.User{}, model.Tokens{}, err
	}

	tokens, err := s.CreateTokens(ctx, user, remember)
	if err != nil {
		return user, model.Tokens{}, nil
	}

	return user, tokens, nil
}

func (s *AuthService) Signup(ctx context.Context, form model.SignupForm) (model.User, error) {
	if err := form.IsValid(); err != nil {
		return model.User{}, fmt.Errorf("form validation: %w", err)
	}

	user, err := s.userS.CreateUser(ctx, model.User{
		Name:     form.Name,
		Email:    form.Email,
		Password: form.Password,
		Role:     model.UserRoleUser,
	})
	if err != nil {
		return model.User{}, err
	}

	return user, nil
}

func (s *AuthService) Login(ctx context.Context, form model.LoginForm, remember bool) (model.User, model.Tokens, error) {
	if err := form.IsValid(); err != nil {
		return model.User{}, model.Tokens{}, fmt.Errorf("form validation: %w", err)
	}

	user, err := s.userS.GetUserByFilter(ctx, model.UserFilter{
		Email: &form.Email,
	})
	if err != nil {
		return model.User{}, model.Tokens{}, err
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(form.Password)); err != nil {
		return model.User{}, model.Tokens{}, model.ErrBadPassword
	}

	tokens, err := s.CreateTokens(ctx, user, remember)
	if err != nil {
		return model.User{}, model.Tokens{}, err
	}

	return user, tokens, nil
}

func (s *AuthService) CreateTokens(ctx context.Context, user model.User, remember bool) (model.Tokens, error) {
	accessToken, err := s.jwtS.CreateAccessToken(ctx, user)
	if err != nil {
		return model.Tokens{}, err
	}

	refreshToken, err := s.sessionS.CreateRefreshToken(ctx, user.ID, remember)
	if err != nil {
		return model.Tokens{}, err
	}

	return model.Tokens{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
	}, nil
}

func (s *AuthService) Logout(ctx context.Context, userID uuid.UUID, token string) error {
	if err := s.sessionS.DeleteSessionByTokenAndUserID(ctx, token, userID); err != nil {
		return err
	}
	return nil
}

func (s *AuthService) RefreshAccessToken(ctx context.Context, token string) (model.AccessToken, error) {
	user, err := s.sessionS.GetUserByValidToken(ctx, token)
	if err != nil {
		return model.AccessToken{}, err
	}

	accessToken, err := s.jwtS.CreateAccessToken(ctx, user)
	if err != nil {
		return model.AccessToken{}, err
	}

	return accessToken, nil
}
