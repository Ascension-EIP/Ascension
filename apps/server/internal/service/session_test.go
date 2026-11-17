// @date 2026-11-13
// @file session_test.go
// @brief Unit tests of the refresh session service: token generation, hashing, expiry and cleanup.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package service

import (
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"net/netip"
	"testing"
	"time"

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/setup/config"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/testutil/memrepo"
)

var testSessionConfig = config.SessionConfig{Secret: "session-test-secret", Exp: 24 * time.Hour, RememberExp: 30 * 24 * time.Hour}

// errRepo is the error injected by the failing repositories of these tests.
var errRepo = errors.New("repository down")

// failingSessionRepo is a memrepo whose refresh session methods fail.
type failingSessionRepo struct {
	*memrepo.Repo
}

func (failingSessionRepo) CreateSession(context.Context, model.Session) (model.Session, error) {
	return model.Session{}, errRepo
}

func (failingSessionRepo) GetUserByValidToken(context.Context, string) (model.User, error) {
	return model.User{}, errRepo
}

func (failingSessionRepo) DeleteSessionByTokenAndUserID(context.Context, string, uuid.UUID) error {
	return errRepo
}

func (failingSessionRepo) DeleteSessionsExpired(context.Context) error {
	return errRepo
}

// createTestUser stores an active user with the password and returns it.
func createTestUser(t *testing.T, repo *memrepo.Repo, username string, email string, password string) model.User {
	t.Helper()

	user, err := repo.CreateUser(context.Background(), model.User{
		Username: model.UserUsername(username),
		Email:    model.UserEmail(email),
		Password: model.UserPassword(password),
		Role:     model.UserRoleUser,
		Status:   model.UserStatusActive,
	})
	if err != nil {
		t.Fatalf("CreateUser() error = %v", err)
	}

	return user
}

func hmacHex(secret string, token string) string {
	mac := hmac.New(sha256.New, []byte(secret))
	mac.Write([]byte(token))
	return hex.EncodeToString(mac.Sum(nil))
}

func TestGenerateSessionToken(t *testing.T) {
	s := NewSessionService(testSessionConfig, memrepo.New())

	seen := map[string]bool{}
	for range 50 {
		token, err := s.GenerateSessionToken()
		if err != nil {
			t.Fatalf("GenerateSessionToken() error = %v", err)
		}
		if len(token) != 64 {
			t.Fatalf("len(token) = %d, want 64 hex characters (32 bytes)", len(token))
		}
		if _, err := hex.DecodeString(token); err != nil {
			t.Fatalf("token %q is not hexadecimal: %v", token, err)
		}
		if seen[token] {
			t.Fatalf("token %q generated twice", token)
		}
		seen[token] = true
	}
}

func TestHashSessionToken(t *testing.T) {
	s := NewSessionService(testSessionConfig, memrepo.New())

	hash, err := s.hashSessionToken("token")
	if err != nil {
		t.Fatalf("hashSessionToken() error = %v", err)
	}
	if want := hmacHex(testSessionConfig.Secret, "token"); hash != want {
		t.Errorf("hashSessionToken() = %q, want HMAC-SHA256 %q", hash, want)
	}

	other := NewSessionService(config.SessionConfig{Secret: "another-secret"}, memrepo.New())
	otherHash, _ := other.hashSessionToken("token")
	if otherHash == hash {
		t.Error("two secrets give the same hash")
	}
}

func TestCreateRefreshToken(t *testing.T) {
	ctx := context.Background()
	userAgent := "Ascension/1.0"
	ip := netip.MustParseAddr("203.0.113.7")
	clientInfo := model.ClientInfo{UserAgent: &userAgent, IPAddress: &ip}

	tests := []struct {
		name     string
		remember bool
		lifetime time.Duration
	}{
		{"short session", false, testSessionConfig.Exp},
		{"remembered session", true, testSessionConfig.RememberExp},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			repo := memrepo.New()
			s := NewSessionService(testSessionConfig, repo)
			user := createTestUser(t, repo, "climber", "climber@example.com", "password123")

			before := time.Now()
			token, err := s.CreateRefreshToken(ctx, user.ID, clientInfo, tt.remember)
			if err != nil {
				t.Fatalf("CreateRefreshToken() error = %v", err)
			}
			after := time.Now()

			sessions := repo.Sessions()
			if len(sessions) != 1 {
				t.Fatalf("stored %d sessions, want 1", len(sessions))
			}
			session := sessions[0]
			if session.TokenHash == token.SessionToken {
				t.Error("the raw token is stored, want its hash only")
			}
			if want := hmacHex(testSessionConfig.Secret, token.SessionToken); session.TokenHash != want {
				t.Errorf("TokenHash = %q, want %q", session.TokenHash, want)
			}
			if session.UserID != user.ID {
				t.Errorf("UserID = %v, want %v", session.UserID, user.ID)
			}
			if session.UserAgent == nil || *session.UserAgent != userAgent || session.IPAddress == nil || *session.IPAddress != ip {
				t.Errorf("client info = (%v, %v), want (%q, %v)", session.UserAgent, session.IPAddress, userAgent, ip)
			}
			if session.ExpiresAt.Before(before.Add(tt.lifetime)) || session.ExpiresAt.After(after.Add(tt.lifetime)) {
				t.Errorf("ExpiresAt = %v, want now + %v", session.ExpiresAt, tt.lifetime)
			}
		})
	}
}

func TestCreateRefreshTokenRepositoryError(t *testing.T) {
	s := NewSessionService(testSessionConfig, failingSessionRepo{memrepo.New()})

	if _, err := s.CreateRefreshToken(context.Background(), uuid.NewV7(), model.ClientInfo{}, false); !errors.Is(err, errRepo) {
		t.Errorf("CreateRefreshToken() error = %v, want %v", err, errRepo)
	}
}

func TestGetUserByValidToken(t *testing.T) {
	ctx := context.Background()
	repo := memrepo.New()
	s := NewSessionService(testSessionConfig, repo)
	user := createTestUser(t, repo, "climber", "climber@example.com", "password123")

	token, err := s.CreateRefreshToken(ctx, user.ID, model.ClientInfo{}, false)
	if err != nil {
		t.Fatalf("CreateRefreshToken() error = %v", err)
	}

	t.Run("finds the owner of a valid token", func(t *testing.T) {
		got, err := s.GetUserByValidToken(ctx, token.SessionToken)
		if err != nil {
			t.Fatalf("GetUserByValidToken() error = %v", err)
		}
		if got.ID != user.ID {
			t.Errorf("user = %v, want %v", got.ID, user.ID)
		}
	})

	t.Run("rejects an unknown token", func(t *testing.T) {
		if _, err := s.GetUserByValidToken(ctx, "unknown"); !errors.Is(err, model.ErrNotFound) {
			t.Errorf("GetUserByValidToken() error = %v, want ErrNotFound", err)
		}
	})

	t.Run("rejects the token under another secret", func(t *testing.T) {
		other := NewSessionService(config.SessionConfig{Secret: "another-secret"}, repo)
		if _, err := other.GetUserByValidToken(ctx, token.SessionToken); !errors.Is(err, model.ErrNotFound) {
			t.Errorf("GetUserByValidToken() error = %v, want ErrNotFound", err)
		}
	})

	t.Run("rejects an expired token", func(t *testing.T) {
		repo.PutSession(model.Session{UserID: user.ID, TokenHash: hmacHex(testSessionConfig.Secret, "expired"), ExpiresAt: time.Now().Add(-time.Minute)})
		if _, err := s.GetUserByValidToken(ctx, "expired"); !errors.Is(err, model.ErrNotFound) {
			t.Errorf("GetUserByValidToken() error = %v, want ErrNotFound", err)
		}
	})

	t.Run("forwards the repository error", func(t *testing.T) {
		failing := NewSessionService(testSessionConfig, failingSessionRepo{repo})
		if _, err := failing.GetUserByValidToken(ctx, token.SessionToken); !errors.Is(err, errRepo) {
			t.Errorf("GetUserByValidToken() error = %v, want %v", err, errRepo)
		}
	})
}

func TestDeleteSessionByTokenAndUserID(t *testing.T) {
	ctx := context.Background()
	repo := memrepo.New()
	s := NewSessionService(testSessionConfig, repo)
	user := createTestUser(t, repo, "climber", "climber@example.com", "password123")
	other := createTestUser(t, repo, "climber2", "climber2@example.com", "password123")

	token, err := s.CreateRefreshToken(ctx, user.ID, model.ClientInfo{}, false)
	if err != nil {
		t.Fatalf("CreateRefreshToken() error = %v", err)
	}

	if err := s.DeleteSessionByTokenAndUserID(ctx, token.SessionToken, other.ID); err != nil {
		t.Fatalf("DeleteSessionByTokenAndUserID(other user) error = %v", err)
	}
	if len(repo.Sessions()) != 1 {
		t.Fatal("another user deleted the session")
	}

	if err := s.DeleteSessionByTokenAndUserID(ctx, token.SessionToken, user.ID); err != nil {
		t.Fatalf("DeleteSessionByTokenAndUserID() error = %v", err)
	}
	if len(repo.Sessions()) != 0 {
		t.Error("the session is still stored")
	}
	if _, err := s.GetUserByValidToken(ctx, token.SessionToken); !errors.Is(err, model.ErrNotFound) {
		t.Errorf("GetUserByValidToken() after delete error = %v, want ErrNotFound", err)
	}

	failing := NewSessionService(testSessionConfig, failingSessionRepo{repo})
	if err := failing.DeleteSessionByTokenAndUserID(ctx, token.SessionToken, user.ID); !errors.Is(err, errRepo) {
		t.Errorf("DeleteSessionByTokenAndUserID() error = %v, want %v", err, errRepo)
	}
}

func TestClearExpiredSessions(t *testing.T) {
	ctx := context.Background()
	repo := memrepo.New()
	s := NewSessionService(testSessionConfig, repo)
	user := createTestUser(t, repo, "climber", "climber@example.com", "password123")
	now := time.Now()

	repo.PutSession(model.Session{UserID: user.ID, TokenHash: "valid", ExpiresAt: now.Add(time.Hour)})
	repo.PutSession(model.Session{UserID: user.ID, TokenHash: "expired", ExpiresAt: now.Add(-time.Hour)})
	repo.PutSession(model.Session{UserID: user.ID, TokenHash: "revoked long ago", ExpiresAt: now.Add(time.Hour), RevokedAt: new(now.Add(-8 * 24 * time.Hour))})
	repo.PutSession(model.Session{UserID: user.ID, TokenHash: "revoked recently", ExpiresAt: now.Add(time.Hour), RevokedAt: new(now.Add(-24 * time.Hour))})

	if err := s.ClearExpiredSessions(ctx); err != nil {
		t.Fatalf("ClearExpiredSessions() error = %v", err)
	}

	kept := map[string]bool{}
	for _, session := range repo.Sessions() {
		kept[session.TokenHash] = true
	}
	if len(kept) != 2 || !kept["valid"] || !kept["revoked recently"] {
		t.Errorf("kept sessions = %v, want valid and revoked recently", kept)
	}

	failing := NewSessionService(testSessionConfig, failingSessionRepo{repo})
	if err := failing.ClearExpiredSessions(ctx); !errors.Is(err, errRepo) {
		t.Errorf("ClearExpiredSessions() error = %v, want %v", err, errRepo)
	}
}
