// @date 2026-11-13
// @file error_paths_test.go
// @brief Endpoint tests that every failing request answers an error with a JSON message, whatever its status code.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package router

import (
	"encoding/json"
	"net/http"
	"testing"

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/testutil/memrepo"
)

// TestFailingRequestsAnswerAnError pins what the skipped known bug tests leave open: the
// exact status code is wrong for these requests, but none of them may succeed, and each
// one answers a JSON error message.
func TestFailingRequestsAnswerAnError(t *testing.T) {
	repo := memrepo.New()
	api := newTestAPI(t, repo)
	registered := api.register("climber1")
	admin := adminToken(api)
	userID := uuid.NewV7()
	token := api.token(userID)

	pending := putCompletedVideo(repo, userID)
	pending.Status = model.VideoStatusPending
	repo.PutVideo(pending)
	unknown := uuid.NewV7().String()

	requests := []struct {
		name         string
		method, path string
		token        string
		body         any
	}{
		{"duplicate register", http.MethodPost, "/v1/auth/register", "", registerBody("climber1")},
		{"short username", http.MethodPost, "/v1/auth/register", "", registerBody("short")},
		{"wrong password", http.MethodPost, "/v1/auth/login", "", map[string]any{"identifier": "climber1", "password": "wrong-password"}},
		{"unknown login", http.MethodPost, "/v1/auth/login", "", map[string]any{"identifier": "nobody@example.com", "password": "correct-horse"}},
		{"unknown refresh token", http.MethodPut, "/v1/auth/refresh", "", map[string]any{"refresh_token": "unknown"}},
		{"unknown user", http.MethodGet, "/v1/users/" + unknown, admin, nil},
		{"invalid user role", http.MethodPost, "/v1/users/", admin, map[string]any{"username": "climber2", "first_name": "A", "last_name": "B", "email": "a@b.co", "password": "correct-horse", "role": "root"}},
		{"invalid user update", http.MethodPut, "/v1/users/" + registered.User.ID.String(), admin, map[string]any{"username": "short", "email": "a@b.co", "password": "correct-horse", "role": "user", "status": "active"}},
		{"missing profile", http.MethodGet, "/v1/profile", token, nil},
		{"empty profile update", http.MethodPut, "/v1/profile", registered.AccessToken, map[string]any{}},
		{"unknown visibility", http.MethodPost, "/v1/videos/upload-url", token, map[string]any{"content_type": "video/mp4", "size": 1, "visibility": "everyone"}},
		{"unknown video", http.MethodGet, "/v1/videos/" + unknown, token, nil},
		{"pending download", http.MethodGet, "/v1/videos/download-url/" + pending.ID.String(), token, nil},
		{"upload not done", http.MethodPut, "/v1/videos/upload-done/" + pending.ID.String(), token, nil},
		{"invalid analysis type", http.MethodPost, "/v1/analysis/", token, map[string]any{"video_id": pending.ID, "type": "4d", "visibility": "private"}},
		{"unknown analysis", http.MethodGet, "/v1/analysis/" + unknown, token, nil},
	}

	for _, tt := range requests {
		t.Run(tt.name, func(t *testing.T) {
			rec := api.do(tt.method, tt.path, tt.token, tt.body)
			if rec.Code < 400 {
				t.Fatalf("status = %d, want an error (body: %s)", rec.Code, rec.Body.String())
			}
			var body struct {
				Error string `json:"error"`
			}
			if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil || body.Error == "" {
				t.Errorf("body = %s, want a JSON error message", rec.Body.String())
			}
		})
	}
}
