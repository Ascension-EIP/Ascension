// @date 2026-11-13
// @file jwt_test.go
// @brief Unit tests of the JWT service: access token signing and every rejected token.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package service

import (
	"context"
	"crypto/rand"
	"crypto/rsa"
	"strings"
	"testing"
	"time"

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/setup/config"
	"github.com/golang-jwt/jwt/v5"
)

const testJWTSecret = "jwt-test-secret"

func newTestJWTService(exp time.Duration) JWTService {
	return NewJWTService(config.JWTConfig{Exp: exp, Secret: testJWTSecret})
}

func testUser() model.User {
	return model.User{
		ID:        uuid.NewV7(),
		Username:  "climber",
		FirstName: "Alex",
		LastName:  "Honnold",
		Email:     "alex@example.com",
		Role:      model.UserRoleCoach,
	}
}

func TestCreateAccessToken(t *testing.T) {
	ctx := context.Background()
	s := newTestJWTService(15 * time.Minute)
	user := testUser()

	before := time.Now().Add(-time.Second)
	token, err := s.CreateAccessToken(ctx, user)
	if err != nil {
		t.Fatalf("CreateAccessToken() error = %v", err)
	}

	if token.TokenType != "Bearer" {
		t.Errorf("TokenType = %q, want Bearer", token.TokenType)
	}
	if token.ExpiresIn != 900 {
		t.Errorf("ExpiresIn = %d, want 900", token.ExpiresIn)
	}

	claims, err := s.ValidateAccessToken(ctx, token.Token)
	if err != nil {
		t.Fatalf("ValidateAccessToken() error = %v", err)
	}
	if claims.UserID != user.ID || claims.UserUsername != user.Username || claims.UserFirstName != user.FirstName ||
		claims.UserLastName != user.LastName || claims.UserEmail != user.Email || claims.UserRole != user.Role {
		t.Errorf("claims = %+v, want the fields of %+v", claims, user)
	}
	if claims.IssuedAt == nil || claims.IssuedAt.Before(before) {
		t.Errorf("IssuedAt = %v, want about now", claims.IssuedAt)
	}
	if claims.ExpiresAt == nil || claims.ExpiresAt.Sub(claims.IssuedAt.Time) != 15*time.Minute {
		t.Errorf("ExpiresAt = %v, want IssuedAt + 15m", claims.ExpiresAt)
	}
}

func TestCreateAccessTokenIsSignedWithHS256(t *testing.T) {
	s := newTestJWTService(time.Minute)

	token, err := s.CreateAccessToken(context.Background(), testUser())
	if err != nil {
		t.Fatalf("CreateAccessToken() error = %v", err)
	}

	parsed, _, err := jwt.NewParser().ParseUnverified(token.Token, &model.JWTClaims{})
	if err != nil {
		t.Fatalf("ParseUnverified() error = %v", err)
	}
	if alg := parsed.Method.Alg(); alg != "HS256" {
		t.Errorf("alg = %q, want HS256", alg)
	}
}

func TestValidateAccessTokenRejects(t *testing.T) {
	ctx := context.Background()
	s := newTestJWTService(time.Minute)
	user := testUser()

	sign := func(t *testing.T, method jwt.SigningMethod, key any, expiresAt time.Time) string {
		t.Helper()
		claims := model.JWTClaims{
			UserID:           user.ID,
			UserUsername:     user.Username,
			UserRole:         user.Role,
			RegisteredClaims: jwt.RegisteredClaims{ExpiresAt: jwt.NewNumericDate(expiresAt), IssuedAt: jwt.NewNumericDate(time.Now())},
		}
		token, err := jwt.NewWithClaims(method, claims).SignedString(key)
		if err != nil {
			t.Fatalf("SignedString() error = %v", err)
		}
		return token
	}

	rsaKey, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		t.Fatalf("GenerateKey() error = %v", err)
	}

	valid, err := s.CreateAccessToken(ctx, user)
	if err != nil {
		t.Fatalf("CreateAccessToken() error = %v", err)
	}
	parts := strings.Split(valid.Token, ".")

	tests := []struct {
		name  string
		token string
	}{
		{"an expired token", sign(t, jwt.SigningMethodHS256, []byte(testJWTSecret), time.Now().Add(-time.Minute))},
		{"a token signed with another secret", sign(t, jwt.SigningMethodHS256, []byte("another-secret"), time.Now().Add(time.Minute))},
		{"an unsigned token (alg none)", sign(t, jwt.SigningMethodNone, jwt.UnsafeAllowNoneSignatureType, time.Now().Add(time.Minute))},
		{"a token signed with RS256", sign(t, jwt.SigningMethodRS256, rsaKey, time.Now().Add(time.Minute))},
		{"a tampered payload", parts[0] + "." + parts[0] + "." + parts[2]},
		{"a token without signature", parts[0] + "." + parts[1] + "."},
		{"garbage", "not-a-jwt"},
		{"an empty token", ""},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			claims, err := s.ValidateAccessToken(ctx, tt.token)
			if err == nil {
				t.Fatalf("ValidateAccessToken() = %+v, want an error", claims)
			}
			if claims != nil {
				t.Errorf("claims = %+v, want nil", claims)
			}
		})
	}
}

func TestValidateAccessTokenOfAnotherService(t *testing.T) {
	ctx := context.Background()
	other := NewJWTService(config.JWTConfig{Exp: time.Minute, Secret: "other-secret"})

	token, err := other.CreateAccessToken(ctx, testUser())
	if err != nil {
		t.Fatalf("CreateAccessToken() error = %v", err)
	}

	s := newTestJWTService(time.Minute)
	if _, err := s.ValidateAccessToken(ctx, token.Token); err == nil {
		t.Error("ValidateAccessToken() error = nil, want the signature error")
	}
}
