// @date 2026-09-20
// @file auth.go
// @brief File description.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>, DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package service

import (
	"context"
	"fmt"
	"strings"

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"golang.org/x/crypto/bcrypt"
)

type AuthService struct {
	jwtS         *JWTService
	sessionS     *SessionService
	userS        *UserService
	userProfileS *UserProfileService
	repoT        model.TransactionRepository
}

func NewAuthService(jwtS *JWTService, sessionS *SessionService, userS *UserService, userProfileS *UserProfileService, repoT model.TransactionRepository) AuthService {
	return AuthService{
		jwtS:         jwtS,
		sessionS:     sessionS,
		userS:        userS,
		userProfileS: userProfileS,
		repoT:        repoT,
	}
}

func (s *AuthService) SignupAndLogin(ctx context.Context, form model.SignupForm, clienInfo model.ClientInfo, remember bool) (model.User, model.Tokens, error) {
	user, err := s.Signup(ctx, form)
	if err != nil {
		return model.User{}, model.Tokens{}, fmt.Errorf("signup: %w", err)
	}

	tokens, err := s.CreateTokens(ctx, user, clienInfo, remember)
	if err != nil {
		return user, model.Tokens{}, err
	}

	return user, tokens, nil
}

func (s *AuthService) Signup(ctx context.Context, form model.SignupForm) (model.User, error) {
	if err := form.Validate(); err != nil {
		return model.User{}, fmt.Errorf("form validation: %w", err)
	}

	var user model.User
	if err := s.repoT.WithTransaction(ctx, func(ctx context.Context) error {
		var err error

		user, err = s.userS.CreateUser(ctx, model.User{
			Username:  form.Username,
			FirstName: form.FirstName,
			LastName:  form.LastName,
			Email:     form.Email,
			Password:  form.Password,
			Role:      model.UserRoleUser,
			Status:    model.UserStatusActive,
		})
		if err != nil {
			return fmt.Errorf("create user: %w", err)
		}

		if _, err := s.userProfileS.CreateUserProfile(ctx, model.UserProfile{
			UserID: user.ID,
		}); err != nil {
			return fmt.Errorf("create user profile: %w", err)
		}

		return nil
	}); err != nil {
		return model.User{}, fmt.Errorf("transaction: %w", err)
	}

	return user, nil
}

func (s *AuthService) Login(ctx context.Context, form model.LoginForm, clientInfo model.ClientInfo, remember bool) (model.User, model.Tokens, error) {
	if err := form.Validate(); err != nil {
		return model.User{}, model.Tokens{}, fmt.Errorf("form validation: %w", err)
	}

	var user model.User
	var err error
	if strings.Contains(form.Identifier, "@") {
		user, err = s.userS.GetUserByFilter(ctx, model.UserFilter{
			Email: new(model.NewUserEmail(form.Identifier)),
		})
		if err != nil {
			return model.User{}, model.Tokens{}, err
		}
	} else {
		user, err = s.userS.GetUserByFilter(ctx, model.UserFilter{
			Username: new(model.UserUsername(form.Identifier)),
		})
		if err != nil {
			return model.User{}, model.Tokens{}, err
		}
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(form.Password)); err != nil {
		return model.User{}, model.Tokens{}, model.ErrBadPassword
	}

	tokens, err := s.CreateTokens(ctx, user, clientInfo, remember)
	if err != nil {
		return model.User{}, model.Tokens{}, err
	}

	return user, tokens, nil
}

func (s *AuthService) CreateTokens(ctx context.Context, user model.User, clientInfo model.ClientInfo, remember bool) (model.Tokens, error) {
	accessToken, err := s.jwtS.CreateAccessToken(ctx, user)
	if err != nil {
		return model.Tokens{}, err
	}

	refreshToken, err := s.sessionS.CreateRefreshToken(ctx, user.ID, clientInfo, remember)
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
