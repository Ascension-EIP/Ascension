// @date 2026-11-13
// @file auth_test.go
// @brief Unit tests of the auth service: register, login, logout and access token refresh.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package service

import (
	"context"
	"errors"
	"testing"
	"time"

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/setup/config"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/testutil/memrepo"
)

// failingProfileRepo is a memrepo whose profile creation fails.
type failingProfileRepo struct {
	*memrepo.Repo
}

func (failingProfileRepo) CreateUserProfile(context.Context, model.UserProfile) (model.UserProfile, error) {
	return model.UserProfile{}, errRepo
}

// testAuth is an auth service and the services it is built on.
type testAuth struct {
	auth AuthService
	jwt  *JWTService
	repo *memrepo.Repo
}

// newTestAuth builds the auth service on the repo; userRepo and sessionRepo replace it
// for the users and the refresh sessions when they are not nil.
func newTestAuth(repo *memrepo.Repo, userRepo model.UserRepository, sessionRepo model.SessionRepository) testAuth {
	if userRepo == nil {
		userRepo = repo
	}
	if sessionRepo == nil {
		sessionRepo = repo
	}

	jwtS := NewJWTService(config.JWTConfig{Exp: time.Hour, Secret: testJWTSecret})
	sessionS := NewSessionService(testSessionConfig, sessionRepo)
	userS := NewUserService(userRepo)
	userProfileS := NewUserProfileService(userRepo)

	return testAuth{
		auth: NewAuthService(&jwtS, &sessionS, &userS, &userProfileS, repo),
		jwt:  &jwtS,
		repo: repo,
	}
}

func validRegisterForm() model.RegisterForm {
	return model.RegisterForm{
		Username:  "climber",
		FirstName: "Alex",
		LastName:  "Honnold",
		Email:     "alex@example.com",
		Password:  model.UserPassword("password123"),
	}
}

func TestRegister(t *testing.T) {
	ctx := context.Background()

	t.Run("creates the user, its profile and a session", func(t *testing.T) {
		a := newTestAuth(memrepo.New(), nil, nil)

		user, tokens, err := a.auth.Register(ctx, validRegisterForm(), model.ClientInfo{}, false)
		if err != nil {
			t.Fatalf("Register() error = %v", err)
		}

		if user.Role != model.UserRoleUser || user.Status != model.UserStatusActive {
			t.Errorf("(role, status) = (%q, %q), want (user, active)", user.Role, user.Status)
		}
		if _, ok := a.repo.Profile(user.ID); !ok {
			t.Error("no profile was created")
		}
		if len(a.repo.Sessions()) != 1 {
			t.Errorf("stored %d sessions, want 1", len(a.repo.Sessions()))
		}
		claims, err := a.jwt.ValidateAccessToken(ctx, tokens.Token)
		if err != nil || claims.UserID != user.ID {
			t.Errorf("access token = (%+v, %v), want a valid token of the user", claims, err)
		}
		if tokens.SessionToken == "" {
			t.Error("no refresh token")
		}
	})

	invalid := []struct {
		name   string
		mutate func(*model.RegisterForm)
	}{
		{"a too short username", func(f *model.RegisterForm) { f.Username = "short" }},
		{"a too short password", func(f *model.RegisterForm) { f.Password = model.UserPassword("short") }},
	}
	for _, tt := range invalid {
		t.Run("rejects "+tt.name, func(t *testing.T) {
			a := newTestAuth(memrepo.New(), nil, nil)
			form := validRegisterForm()
			tt.mutate(&form)

			if _, _, err := a.auth.Register(ctx, form, model.ClientInfo{}, false); err == nil {
				t.Fatal("Register() error = nil, want a validation error")
			}
			if users, _ := a.repo.ListUsersByFilter(ctx, model.UserFilter{}); len(users) != 0 {
				t.Errorf("stored %d users, want none", len(users))
			}
		})
	}

	t.Run("rejects a taken username", func(t *testing.T) {
		a := newTestAuth(memrepo.New(), nil, nil)
		if _, _, err := a.auth.Register(ctx, validRegisterForm(), model.ClientInfo{}, false); err != nil {
			t.Fatalf("Register() error = %v", err)
		}
		form := validRegisterForm()
		form.Email = "other@example.com"

		if _, _, err := a.auth.Register(ctx, form, model.ClientInfo{}, false); !errors.Is(err, model.ErrConflict) {
			t.Errorf("Register(taken username) error = %v, want ErrConflict", err)
		}
	})

	t.Run("fails when the profile cannot be created", func(t *testing.T) {
		repo := memrepo.New()
		a := newTestAuth(repo, failingProfileRepo{repo}, nil)

		if _, _, err := a.auth.Register(ctx, validRegisterForm(), model.ClientInfo{}, false); !errors.Is(err, errRepo) {
			t.Errorf("Register() error = %v, want %v", err, errRepo)
		}
		if len(repo.Sessions()) != 0 {
			t.Error("a session was created for a failed registration")
		}
	})

	t.Run("returns the user when the session cannot be created", func(t *testing.T) {
		repo := memrepo.New()
		a := newTestAuth(repo, nil, failingSessionRepo{repo})

		user, tokens, err := a.auth.Register(ctx, validRegisterForm(), model.ClientInfo{}, false)
		if !errors.Is(err, errRepo) {
			t.Fatalf("Register() error = %v, want %v", err, errRepo)
		}
		if user.Username != "climber" {
			t.Errorf("user = %+v, want the created user", user)
		}
		if tokens != (model.Tokens{}) {
			t.Errorf("tokens = %+v, want none", tokens)
		}
	})
}

func TestLogin(t *testing.T) {
	ctx := context.Background()
	a := newTestAuth(memrepo.New(), nil, nil)
	registered, _, err := a.auth.Register(ctx, validRegisterForm(), model.ClientInfo{}, false)
	if err != nil {
		t.Fatalf("Register() error = %v", err)
	}

	for _, identifier := range []string{"climber", "alex@example.com", "  Alex@Example.COM "} {
		t.Run("logs in with "+identifier, func(t *testing.T) {
			user, tokens, err := a.auth.Login(ctx, model.LoginForm{Identifier: identifier, Password: model.UserPassword("password123")}, model.ClientInfo{}, true)
			if err != nil {
				t.Fatalf("Login() error = %v", err)
			}
			if user.ID != registered.ID {
				t.Errorf("user = %v, want %v", user.ID, registered.ID)
			}
			if tokens.Token == "" || tokens.SessionToken == "" {
				t.Errorf("tokens = %+v, want an access and a refresh token", tokens)
			}
		})
	}

	t.Run("rejects a wrong password", func(t *testing.T) {
		if _, _, err := a.auth.Login(ctx, model.LoginForm{Identifier: "climber", Password: model.UserPassword("wrong-password")}, model.ClientInfo{}, false); !errors.Is(err, model.ErrBadPassword) {
			t.Errorf("Login() error = %v, want ErrBadPassword", err)
		}
	})

	t.Run("rejects an unknown user", func(t *testing.T) {
		for _, identifier := range []string{"nobody-here", "nobody@example.com"} {
			if _, _, err := a.auth.Login(ctx, model.LoginForm{Identifier: identifier, Password: model.UserPassword("password123")}, model.ClientInfo{}, false); !errors.Is(err, model.ErrNotFound) {
				t.Errorf("Login(%q) error = %v, want ErrNotFound", identifier, err)
			}
		}
	})

	t.Run("rejects an invalid password before any lookup", func(t *testing.T) {
		if _, _, err := a.auth.Login(ctx, model.LoginForm{Identifier: "climber", Password: model.UserPassword("short")}, model.ClientInfo{}, false); err == nil || errors.Is(err, model.ErrBadPassword) {
			t.Errorf("Login() error = %v, want a validation error", err)
		}
	})

	t.Run("fails when the session cannot be created", func(t *testing.T) {
		failing := newTestAuth(a.repo, nil, failingSessionRepo{a.repo})
		user, _, err := failing.auth.Login(ctx, model.LoginForm{Identifier: "climber", Password: model.UserPassword("password123")}, model.ClientInfo{}, false)
		if !errors.Is(err, errRepo) {
			t.Fatalf("Login() error = %v, want %v", err, errRepo)
		}
		if user.ID != (uuid.UUID{}) {
			t.Errorf("user = %+v, want none", user)
		}
	})
}

func TestLogoutAndRefreshAccessToken(t *testing.T) {
	ctx := context.Background()
	a := newTestAuth(memrepo.New(), nil, nil)
	user, tokens, err := a.auth.Register(ctx, validRegisterForm(), model.ClientInfo{}, false)
	if err != nil {
		t.Fatalf("Register() error = %v", err)
	}

	access, err := a.auth.RefreshAccessToken(ctx, tokens.SessionToken)
	if err != nil {
		t.Fatalf("RefreshAccessToken() error = %v", err)
	}
	claims, err := a.jwt.ValidateAccessToken(ctx, access.Token)
	if err != nil || claims.UserID != user.ID {
		t.Errorf("refreshed token = (%+v, %v), want a valid token of the user", claims, err)
	}

	if _, err := a.auth.RefreshAccessToken(ctx, "unknown"); !errors.Is(err, model.ErrNotFound) {
		t.Errorf("RefreshAccessToken(unknown) error = %v, want ErrNotFound", err)
	}

	if err := a.auth.Logout(ctx, user.ID, tokens.SessionToken); err != nil {
		t.Fatalf("Logout() error = %v", err)
	}
	if _, err := a.auth.RefreshAccessToken(ctx, tokens.SessionToken); !errors.Is(err, model.ErrNotFound) {
		t.Errorf("RefreshAccessToken() after logout error = %v, want ErrNotFound", err)
	}

	failing := newTestAuth(a.repo, nil, failingSessionRepo{a.repo})
	if err := failing.auth.Logout(ctx, user.ID, tokens.SessionToken); !errors.Is(err, errRepo) {
		t.Errorf("Logout() error = %v, want %v", err, errRepo)
	}
}
