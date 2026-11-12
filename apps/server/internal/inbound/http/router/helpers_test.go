// @date 2026-11-13
// @file helpers_test.go
// @brief Test helpers: build the real router around a climbing session service and call it over HTTP.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package router

import (
	"bytes"
	"context"
	"encoding/json"
	"io"
	"net/http/httptest"
	"os"
	"testing"
	"time"

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/inbound/http/handler"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/inbound/http/middleware"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/service"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/setup/config"
	"github.com/gin-gonic/gin"
)

func TestMain(m *testing.M) {
	gin.SetMode(gin.TestMode)
	os.Exit(m.Run())
}

// testRepo is what the climbing session, analysis and body constraint services need from
// the database.
type testRepo interface {
	model.ClimbingSessionRepository
	model.AnalysisRepository
	model.VideoRepository
	model.UserBodyConstraintRepository
}

// testAPI is the real router with the real JWT middleware and rate limiters. Only the
// climbing session, analysis and body constraint handlers are wired: the others are nil and must
// not be called.
type testAPI struct {
	t      *testing.T
	engine *gin.Engine
	jwt    service.JWTService
}

func newTestAPI(t *testing.T, repo testRepo) *testAPI {
	t.Helper()

	jwtS := service.NewJWTService(config.JWTConfig{Exp: time.Hour, Secret: "climbing-session-test-secret"})
	sessionS := service.NewClimbingSessionService(repo, repo, repo)
	sessionH := handler.NewClimbingSessionHandler(&sessionS)
	analysisS := service.NewAnalysisService(config.MinIOConfig{BucketName: "videos"}, repo, repo, noQueue{})
	analysisH := handler.NewAnalysisHandler(&analysisS)
	bodyConstraintS := service.NewUserBodyConstraintService(repo)
	bodyConstraintH := handler.NewUserBodyConstraintHandler(&bodyConstraintS)

	engine := gin.New()
	New(engine, config.Config{}, middleware.AuthMiddleware(&jwtS), nil, nil, nil, &analysisH, nil, &sessionH, &bodyConstraintH)

	return &testAPI{t: t, engine: engine, jwt: jwtS}
}

// token returns a valid access token for a user with the given ID.
func (api *testAPI) token(userID uuid.UUID) string {
	api.t.Helper()

	token, err := api.jwt.CreateAccessToken(context.Background(), model.User{ID: userID, Username: "climber", Role: model.UserRoleUser})
	if err != nil {
		api.t.Fatalf("CreateAccessToken() error = %v", err)
	}

	return token.Token
}

// do sends a request; an empty token sends no Authorization header and a nil body sends none.
func (api *testAPI) do(method string, path string, token string, body any) *httptest.ResponseRecorder {
	api.t.Helper()

	var reader io.Reader
	switch b := body.(type) {
	case nil:
	case string:
		reader = bytes.NewBufferString(b)
	default:
		raw, err := json.Marshal(b)
		if err != nil {
			api.t.Fatalf("Marshal() error = %v", err)
		}
		reader = bytes.NewBuffer(raw)
	}

	req := httptest.NewRequest(method, path, reader)
	if reader != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}

	rec := httptest.NewRecorder()
	api.engine.ServeHTTP(rec, req)

	return rec
}

// expect fails the test when the response status is not want, and decodes the body into out.
func expect(t *testing.T, rec *httptest.ResponseRecorder, want int, out any) {
	t.Helper()

	if rec.Code != want {
		t.Fatalf("status = %d, want %d (body: %s)", rec.Code, want, rec.Body.String())
	}

	if out != nil {
		if err := json.Unmarshal(rec.Body.Bytes(), out); err != nil {
			t.Fatalf("Unmarshal(%s) error = %v", rec.Body.String(), err)
		}
	}
}

// noQueue drops the analysis jobs.
type noQueue struct{}

func (noQueue) PublishJSONIntoQueueAI(context.Context, []byte) error { return nil }

type analysisSummaryBody struct {
	ID                uuid.UUID  `json:"id"`
	VideoID           uuid.UUID  `json:"video_id"`
	ClimbingSessionID *uuid.UUID `json:"climbing_session_id"`
	Type              string     `json:"type"`
	Status            string     `json:"status"`
}

type analysisListBody struct {
	Analyses []analysisSummaryBody `json:"analyses"`
	Total    int                   `json:"total"`
	Limit    int                   `json:"limit"`
	Offset   int                   `json:"offset"`
}

type sessionBody struct {
	ID         uuid.UUID             `json:"id"`
	GymID      *uuid.UUID            `json:"gym_id"`
	Title      *string               `json:"title"`
	Notes      *string               `json:"notes"`
	StartedAt  time.Time             `json:"started_at"`
	EndedAt    *time.Time            `json:"ended_at"`
	Visibility string                `json:"visibility"`
	Analyses   []analysisSummaryBody `json:"analyses"`
}

type sessionListBody struct {
	Sessions []sessionBody `json:"sessions"`
	Total    int           `json:"total"`
	Limit    int           `json:"limit"`
	Offset   int           `json:"offset"`
}
