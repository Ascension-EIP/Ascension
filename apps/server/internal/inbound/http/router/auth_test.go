// @date 2026-11-13
// @file auth_test.go
// @brief Endpoint tests of /v1/auth (register, login, refresh, logout) through the real router, with an in-memory repository.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package router

import (
	"github.com/Ascension-EIP/Ascension/apps/server/internal/testutil/knownbug"
	"net/http"
	"testing"
	"time"

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/testutil/memrepo"
)

type userBody struct {
	ID       uuid.UUID `json:"id"`
	Username string    `json:"username"`
	Email    string    `json:"email"`
	Role     string    `json:"role"`
	Status   string    `json:"status"`
}

type accessTokenBody struct {
	AccessToken string `json:"access_token"`
	TokenType   string `json:"token_type"`
	ExpiresIn   uint   `json:"expires_in"`
}

type loginBody struct {
	RefreshToken string `json:"refresh_token"`
	accessTokenBody
	User userBody `json:"user"`
}

// knownBug skips a test that asserts the expected behaviour of a bug not fixed yet. Set
// RUN_KNOWN_BUGS=1 to run it anyway and see it fail.
func knownBug(t *testing.T, bug string) {
	t.Helper()
	knownbug.Skip(t, bug)
}

func registerBody(username string) map[string]any {
	return map[string]any{
		"username":   username,
		"first_name": "Alex",
		"last_name":  "Honnold",
		"email":      username + "@example.com",
		"password":   "correct-horse",
	}
}

// register creates a user through POST /v1/auth/register and returns the response.
func (api *testAPI) register(username string) loginBody {
	api.t.Helper()

	var body loginBody
	expect(api.t, api.do(http.MethodPost, "/v1/auth/register", "", registerBody(username)), http.StatusCreated, &body)
	return body
}

func TestRegister(t *testing.T) {
	repo := memrepo.New()
	api := newTestAPI(t, repo)

	body := registerBody("climber1")
	body["email"] = "Climber1@Example.COM"
	var created loginBody
	expect(t, api.do(http.MethodPost, "/v1/auth/register", "", body), http.StatusCreated, &created)

	if created.RefreshToken == "" || created.AccessToken == "" {
		t.Fatalf("tokens = %+v, want both set", created)
	}
	if created.TokenType != "Bearer" || created.ExpiresIn != uint(time.Hour.Seconds()) {
		t.Errorf("token type / expiry = %q / %d, want Bearer / 3600", created.TokenType, created.ExpiresIn)
	}
	if created.User.Username != "climber1" || created.User.Role != string(model.UserRoleUser) || created.User.Status != string(model.UserStatusActive) {
		t.Errorf("user = %+v, want an active user climber1", created.User)
	}
	if created.User.Email != "climber1@example.com" {
		t.Errorf("email = %q, want it lowercased", created.User.Email)
	}

	stored, ok := repo.User(created.User.ID)
	if !ok {
		t.Fatalf("user %v not stored", created.User.ID)
	}
	if string(stored.Password) == "correct-horse" {
		t.Error("password stored in clear text")
	}
	if _, ok := repo.Profile(created.User.ID); !ok {
		t.Error("register did not create the user profile")
	}

	sessions := repo.Sessions()
	if len(sessions) != 1 || sessions[0].UserID != created.User.ID {
		t.Fatalf("sessions = %+v, want one session of the new user", sessions)
	}
	if sessions[0].TokenHash == created.RefreshToken {
		t.Error("refresh token stored in clear text")
	}
	if sessions[0].IPAddress == nil {
		t.Error("session IP address not recorded")
	}

	// The access token is accepted by the protected routes.
	expect(t, api.do(http.MethodGet, "/v1/profile", created.AccessToken, nil), http.StatusOK, nil)
}

func TestRegisterRememberExtendsTheRefreshSession(t *testing.T) {
	for _, remember := range []bool{false, true} {
		repo := memrepo.New()
		api := newTestAPI(t, repo)

		body := registerBody("climber1")
		body["remember"] = remember
		before := time.Now()
		expect(t, api.do(http.MethodPost, "/v1/auth/register", "", body), http.StatusCreated, nil)

		want := time.Hour
		if remember {
			want = 24 * time.Hour
		}
		sessions := repo.Sessions()
		if len(sessions) != 1 {
			t.Fatalf("remember=%v: %d sessions, want 1", remember, len(sessions))
		}
		if got := sessions[0].ExpiresAt.Sub(before); got < want || got > want+time.Minute {
			t.Errorf("remember=%v: session lasts %v, want %v", remember, got, want)
		}
	}
}

func TestRegisterInvalidBodies(t *testing.T) {
	tests := []struct {
		name string
		body any
	}{
		{"not json", "{"},
		{"no body", nil},
		{"missing username", map[string]any{"first_name": "A", "last_name": "B", "email": "a@b.co", "password": "correct-horse"}},
		{"missing password", map[string]any{"username": "climber1", "first_name": "A", "last_name": "B", "email": "a@b.co"}},
		{"invalid email", map[string]any{"username": "climber1", "first_name": "A", "last_name": "B", "email": "not-an-email", "password": "correct-horse"}},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			api := newTestAPI(t, memrepo.New())
			expect(t, api.do(http.MethodPost, "/v1/auth/register", "", tt.body), http.StatusBadRequest, nil)
		})
	}
}

func TestRegisterRejectsInvalidForm(t *testing.T) {
	knownBug(t, "model validation errors (username length, password length) do not wrap model.ErrInvalidInput, so utils.Error answers 500")

	for _, field := range []struct{ key, value string }{{"username", "short"}, {"password", "short"}} {
		api := newTestAPI(t, memrepo.New())
		body := registerBody("climber1")
		body[field.key] = field.value
		expect(t, api.do(http.MethodPost, "/v1/auth/register", "", body), http.StatusUnprocessableEntity, nil)
	}
}

func TestRegisterDuplicateUsername(t *testing.T) {
	knownBug(t, "the unique violation becomes model.ErrConflict, which utils.Error does not map: 500 instead of 409")

	api := newTestAPI(t, memrepo.New())
	api.register("climber1")
	expect(t, api.do(http.MethodPost, "/v1/auth/register", "", registerBody("climber1")), http.StatusConflict, nil)
}

func TestRegisterIsRateLimited(t *testing.T) {
	api := newTestAPI(t, memrepo.New())

	for i := range 5 {
		api.register("climber" + string(rune('a'+i)))
	}
	expect(t, api.do(http.MethodPost, "/v1/auth/register", "", registerBody("climberz")), http.StatusTooManyRequests, nil)
}

func TestLogin(t *testing.T) {
	repo := memrepo.New()
	api := newTestAPI(t, repo)
	registered := api.register("climber1")

	for _, identifier := range []string{"climber1", "climber1@example.com", "Climber1@Example.com"} {
		t.Run(identifier, func(t *testing.T) {
			var logged loginBody
			rec := api.do(http.MethodPost, "/v1/auth/login", "", map[string]any{"identifier": identifier, "password": "correct-horse"})
			expect(t, rec, http.StatusCreated, &logged)

			if logged.User.ID != registered.User.ID {
				t.Errorf("user = %v, want %v", logged.User.ID, registered.User.ID)
			}
			if logged.AccessToken == "" || logged.RefreshToken == "" {
				t.Errorf("tokens = %+v, want both set", logged)
			}
		})
	}

	if got := len(repo.Sessions()); got != 4 {
		t.Errorf("%d sessions, want one per register or login (4)", got)
	}
}

func TestLoginInvalidBodies(t *testing.T) {
	tests := []struct {
		name string
		body any
	}{
		{"not json", "{"},
		{"missing identifier", map[string]any{"password": "correct-horse"}},
		{"missing password", map[string]any{"identifier": "climber1"}},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			api := newTestAPI(t, memrepo.New())
			expect(t, api.do(http.MethodPost, "/v1/auth/login", "", tt.body), http.StatusBadRequest, nil)
		})
	}
}

func TestLoginWrongCredentials(t *testing.T) {
	knownBug(t, "model.ErrBadPassword and the not found user are not mapped by utils.Error: login answers 500 instead of 401")

	api := newTestAPI(t, memrepo.New())
	api.register("climber1")

	expect(t, api.do(http.MethodPost, "/v1/auth/login", "", map[string]any{"identifier": "climber1", "password": "wrong-password"}), http.StatusUnauthorized, nil)
	expect(t, api.do(http.MethodPost, "/v1/auth/login", "", map[string]any{"identifier": "nobody99", "password": "correct-horse"}), http.StatusUnauthorized, nil)
}

func TestLoginIsRateLimited(t *testing.T) {
	api := newTestAPI(t, memrepo.New())
	api.register("climber1")
	login := map[string]any{"identifier": "climber1", "password": "correct-horse"}

	for range 10 {
		expect(t, api.do(http.MethodPost, "/v1/auth/login", "", login), http.StatusCreated, nil)
	}
	expect(t, api.do(http.MethodPost, "/v1/auth/login", "", login), http.StatusTooManyRequests, nil)
}

func TestRefreshToken(t *testing.T) {
	api := newTestAPI(t, memrepo.New())
	registered := api.register("climber1")

	var refreshed accessTokenBody
	expect(t, api.do(http.MethodPut, "/v1/auth/refresh", "", map[string]any{"refresh_token": registered.RefreshToken}), http.StatusCreated, &refreshed)

	if refreshed.AccessToken == "" || refreshed.TokenType != "Bearer" {
		t.Fatalf("access token = %+v, want a bearer token", refreshed)
	}
	expect(t, api.do(http.MethodGet, "/v1/profile", refreshed.AccessToken, nil), http.StatusOK, nil)
}

func TestRefreshTokenInvalidBodies(t *testing.T) {
	for _, body := range []any{"{", nil, map[string]any{}} {
		api := newTestAPI(t, memrepo.New())
		expect(t, api.do(http.MethodPut, "/v1/auth/refresh", "", body), http.StatusBadRequest, nil)
	}
}

func TestRefreshTokenRejectsUnknownAndExpiredTokens(t *testing.T) {
	knownBug(t, "an unknown or expired refresh token is not mapped by utils.Error (model.ErrNotFound / pgx.ErrNoRows): 500 instead of 401")

	repo := memrepo.New()
	api := newTestAPI(t, repo)
	registered := api.register("climber1")

	expect(t, api.do(http.MethodPut, "/v1/auth/refresh", "", map[string]any{"refresh_token": "unknown"}), http.StatusUnauthorized, nil)

	repo.SetNow(func() time.Time { return time.Now().Add(2 * time.Hour) })
	expect(t, api.do(http.MethodPut, "/v1/auth/refresh", "", map[string]any{"refresh_token": registered.RefreshToken}), http.StatusUnauthorized, nil)
}

func TestLogout(t *testing.T) {
	repo := memrepo.New()
	api := newTestAPI(t, repo)
	registered := api.register("climber1")
	other := api.register("climber2")

	expect(t, api.do(http.MethodDelete, "/v1/auth/logout", "", map[string]any{"refresh_token": registered.RefreshToken}), http.StatusUnauthorized, nil)
	expect(t, api.do(http.MethodDelete, "/v1/auth/logout", registered.AccessToken, "{"), http.StatusBadRequest, nil)
	expect(t, api.do(http.MethodDelete, "/v1/auth/logout", registered.AccessToken, map[string]any{}), http.StatusBadRequest, nil)

	// Another user's refresh token is left alone.
	expect(t, api.do(http.MethodDelete, "/v1/auth/logout", registered.AccessToken, map[string]any{"refresh_token": other.RefreshToken}), http.StatusNoContent, nil)
	if got := len(repo.Sessions()); got != 2 {
		t.Fatalf("%d sessions after logging out another user's token, want 2", got)
	}

	expect(t, api.do(http.MethodDelete, "/v1/auth/logout", registered.AccessToken, map[string]any{"refresh_token": registered.RefreshToken}), http.StatusNoContent, nil)
	for _, session := range repo.Sessions() {
		if session.UserID == registered.User.ID {
			t.Fatalf("session %v still stored after logout", session.ID)
		}
	}

	// The refresh token no longer gives an access token.
	if rec := api.do(http.MethodPut, "/v1/auth/refresh", "", map[string]any{"refresh_token": registered.RefreshToken}); rec.Code < 400 {
		t.Errorf("refresh after logout: status = %d, want an error", rec.Code)
	}
}
