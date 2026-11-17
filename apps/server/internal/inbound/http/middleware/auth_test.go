// @date 2026-11-13
// @file auth_test.go
// @brief Unit tests of the JWT authentication middleware and its role check.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package middleware

import (
	"context"
	"net/http"
	"testing"
	"time"

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/inbound/http/macro"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/service"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/setup/config"
	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

const testSecret = "middleware-test-secret"

var testUser = model.User{
	ID:        uuid.NewV7(),
	Username:  "climber1",
	FirstName: "Alex",
	LastName:  "Honnold",
	Email:     "alex@example.com",
	Role:      model.UserRoleUser,
}

func signedToken(t *testing.T, secret string, exp time.Duration, user model.User) string {
	t.Helper()

	s := service.NewJWTService(config.JWTConfig{Exp: exp, Secret: secret})
	token, err := s.CreateAccessToken(context.Background(), user)
	if err != nil {
		t.Fatalf("CreateAccessToken() error = %v", err)
	}
	return token.Token
}

// authEngine protects GET /me with the middleware and the roles; the handler records
// that it ran and answers the user found in the context.
func authEngine(roles ...model.UserRole) (*gin.Engine, *bool) {
	jwtS := service.NewJWTService(config.JWTConfig{Exp: time.Hour, Secret: testSecret})
	ran := false

	engine := gin.New()
	engine.GET("/me", AuthMiddleware(&jwtS)(roles...), func(c *gin.Context) {
		ran = true
		user, ok := c.Get(macro.Me)
		if !ok {
			c.Status(http.StatusInternalServerError)
			return
		}
		c.JSON(http.StatusOK, user)
	})

	return engine, &ran
}

func TestAuthMiddlewareRejectsMissingAndInvalidTokens(t *testing.T) {
	noneToken, err := jwt.NewWithClaims(jwt.SigningMethodNone, model.JWTClaims{UserID: testUser.ID, UserRole: model.UserRoleAdmin}).
		SignedString(jwt.UnsafeAllowNoneSignatureType)
	if err != nil {
		t.Fatalf("SignedString(none) error = %v", err)
	}

	tests := []struct {
		name   string
		header string
	}{
		{"no header", ""},
		{"basic scheme", "Basic dXNlcjpwYXNz"},
		{"bearer without space", "Bearer" + signedToken(t, testSecret, time.Hour, testUser)},
		{"lowercase scheme", "bearer " + signedToken(t, testSecret, time.Hour, testUser)},
		{"empty token", "Bearer "},
		{"not a jwt", "Bearer not-a-jwt"},
		{"other secret", "Bearer " + signedToken(t, "another-secret", time.Hour, testUser)},
		{"expired", "Bearer " + signedToken(t, testSecret, -time.Minute, testUser)},
		{"alg none", "Bearer " + noneToken},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			engine, ran := authEngine()
			header := map[string]string{}
			if tt.header != "" {
				header["Authorization"] = tt.header
			}

			rec := serve(engine, http.MethodGet, "/me", "", header)
			if rec.Code != http.StatusUnauthorized {
				t.Errorf("status = %d, want 401", rec.Code)
			}
			if *ran {
				t.Error("the protected handler ran")
			}
		})
	}
}

func TestAuthMiddlewareSetsTheUser(t *testing.T) {
	engine, ran := authEngine()
	rec := serve(engine, http.MethodGet, "/me", "", map[string]string{"Authorization": "Bearer " + signedToken(t, testSecret, time.Hour, testUser)})

	if rec.Code != http.StatusOK || !*ran {
		t.Fatalf("status = %d, ran = %v, want 200 and the handler run", rec.Code, *ran)
	}

	// The context holds a model.User built from the claims, without the password.
	jwtS := service.NewJWTService(config.JWTConfig{Exp: time.Hour, Secret: testSecret})
	var got model.User
	typed := gin.New()
	typed.GET("/", AuthMiddleware(&jwtS)(), func(c *gin.Context) {
		got = c.MustGet(macro.Me).(model.User)
	})
	serve(typed, http.MethodGet, "/", "", map[string]string{"Authorization": "Bearer " + signedToken(t, testSecret, time.Hour, testUser)})

	want := testUser
	if got.ID != want.ID || got.Username != want.Username || got.FirstName != want.FirstName ||
		got.LastName != want.LastName || got.Email != want.Email || got.Role != want.Role || got.Password != nil {
		t.Errorf("context user = %+v, want %+v", got, want)
	}
}

func TestAuthMiddlewareChecksTheRole(t *testing.T) {
	tests := []struct {
		name  string
		roles []model.UserRole
		role  model.UserRole
		want  int
	}{
		{"any role", nil, model.UserRoleGym, http.StatusOK},
		{"admin required, user", []model.UserRole{model.UserRoleAdmin}, model.UserRoleUser, http.StatusUnauthorized},
		{"admin required, admin", []model.UserRole{model.UserRoleAdmin}, model.UserRoleAdmin, http.StatusOK},
		{"coach or gym, gym", []model.UserRole{model.UserRoleCoach, model.UserRoleGym}, model.UserRoleGym, http.StatusOK},
		{"coach or gym, admin", []model.UserRole{model.UserRoleCoach, model.UserRoleGym}, model.UserRoleAdmin, http.StatusUnauthorized},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			engine, ran := authEngine(tt.roles...)
			user := testUser
			user.Role = tt.role

			rec := serve(engine, http.MethodGet, "/me", "", map[string]string{"Authorization": "Bearer " + signedToken(t, testSecret, time.Hour, user)})
			if rec.Code != tt.want {
				t.Errorf("status = %d, want %d", rec.Code, tt.want)
			}
			if *ran != (tt.want == http.StatusOK) {
				t.Errorf("handler ran = %v, want %v", *ran, tt.want == http.StatusOK)
			}
		})
	}
}
