// @date 2026-11-13
// @file helpers_test.go
// @brief Test helpers: build the real router around the services and call it over HTTP.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package router

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http/httptest"
	"net/url"
	"os"
	"sync"
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

// testRepo is what the services behind the router need from the database.
type testRepo interface {
	model.UserRepository
	model.SessionRepository
	model.ClimbingSessionRepository
	model.AnalysisRepository
	model.VideoRepository
	model.UserBodyConstraintRepository
	model.FriendshipRepository
	model.FeedRepository
}

// testJWTSecret signs the access tokens of the test API.
const testJWTSecret = "climbing-session-test-secret"

// testAPI is the real router with the real JWT middleware, rate limiters, services and
// handlers. The object storage and the analysis queue are in-memory fakes.
type testAPI struct {
	t       *testing.T
	engine  *gin.Engine
	jwt     service.JWTService
	storage *fakeStorage
	queue   *fakeQueue
}

func newTestAPI(t *testing.T, repo testRepo) *testAPI {
	t.Helper()

	jwtS := service.NewJWTService(config.JWTConfig{Exp: time.Hour, Secret: testJWTSecret})
	storage := newFakeStorage()
	queue := &fakeQueue{}

	refreshS := service.NewSessionService(config.SessionConfig{Exp: time.Hour, RememberExp: 24 * time.Hour, Secret: "refresh-test-secret"}, repo)
	userS := service.NewUserService(repo)
	userH := handler.NewUserHandler(&userS)
	profileS := service.NewUserProfileService(repo)
	profileH := handler.NewUserProfileHandler(&profileS)
	authS := service.NewAuthService(&jwtS, &refreshS, &userS, &profileS, repo)
	authH := handler.NewAuthHandler(&authS)
	videoS := service.NewVideoService(config.VideoConfig{Retention: time.Hour}, config.StorageConfig{UploadExp: time.Hour}, storage, repo, repo)
	videoH := handler.NewVideoHandler(&videoS)
	sessionS := service.NewClimbingSessionService(repo, repo, repo)
	sessionH := handler.NewClimbingSessionHandler(&sessionS)
	analysisS := service.NewAnalysisService(config.StorageConfig{}, repo, repo, queue)
	analysisH := handler.NewAnalysisHandler(&analysisS)
	bodyConstraintS := service.NewUserBodyConstraintService(repo)
	bodyConstraintH := handler.NewUserBodyConstraintHandler(&bodyConstraintS)
	friendshipS := service.NewFriendshipService(repo)
	friendshipH := handler.NewFriendshipHandler(&friendshipS)
	feedS := service.NewFeedService(repo)
	feedH := handler.NewFeedHandler(&feedS)

	engine := gin.New()
	New(engine, config.Config{}, middleware.AuthMiddleware(&jwtS), &userH, &authH, &videoH, &analysisH, &profileH, &sessionH, &bodyConstraintH, &friendshipH, &feedH)

	return &testAPI{t: t, engine: engine, jwt: jwtS, storage: storage, queue: queue}
}

// token returns a valid access token for a user with the given ID.
func (api *testAPI) token(userID uuid.UUID) string {
	api.t.Helper()

	return api.tokenFor(model.User{ID: userID, Username: "climber", Role: model.UserRoleUser})
}

// tokenFor returns a valid access token carrying the user's claims, role included.
func (api *testAPI) tokenFor(user model.User) string {
	api.t.Helper()

	token, err := api.jwt.CreateAccessToken(context.Background(), user)
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

// fakeQueue records the published analysis jobs, or fails with err when it is set.
type fakeQueue struct {
	mu       sync.Mutex
	err      error
	messages [][]byte
}

func (q *fakeQueue) PublishPoseDetectRequested(_ context.Context, body []byte) error {
	q.mu.Lock()
	defer q.mu.Unlock()

	if q.err != nil {
		return q.err
	}
	q.messages = append(q.messages, body)
	return nil
}

// published returns a copy of the published job bodies.
func (q *fakeQueue) published() [][]byte {
	q.mu.Lock()
	defer q.mu.Unlock()

	return append([][]byte(nil), q.messages...)
}

// errStorage is the error the fake storage returns when it is told to fail.
var errStorage = errors.New("storage unavailable")

// fakeStorage presigns fake URLs and tells which object keys were uploaded.
type fakeStorage struct {
	mu       sync.Mutex
	uploaded map[string]bool
	fail     bool
}

func newFakeStorage() *fakeStorage {
	return &fakeStorage{uploaded: map[string]bool{}}
}

var fakeStorageExpiry = time.Date(2026, 11, 13, 12, 0, 0, 0, time.UTC)

func (s *fakeStorage) PresignedUploadURL(_ context.Context, key string) (*url.URL, time.Time, error) {
	if s.failing() {
		return nil, time.Time{}, errStorage
	}
	return &url.URL{Scheme: "https", Host: "storage.test", Path: "/upload/" + key}, fakeStorageExpiry, nil
}

func (s *fakeStorage) PresignedDownloadURL(_ context.Context, key string) (*url.URL, time.Time, error) {
	if s.failing() {
		return nil, time.Time{}, errStorage
	}
	return &url.URL{Scheme: "https", Host: "storage.test", Path: "/download/" + key}, fakeStorageExpiry, nil
}

func (s *fakeStorage) FileExist(_ context.Context, key string) (bool, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	if s.fail {
		return false, errStorage
	}
	return s.uploaded[key], nil
}

func (s *fakeStorage) Delete(_ context.Context, key string) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	delete(s.uploaded, key)
	return nil
}

// upload marks the object key as uploaded.
func (s *fakeStorage) upload(key string) {
	s.mu.Lock()
	defer s.mu.Unlock()

	s.uploaded[key] = true
}

// setFailing makes every call fail with errStorage, or succeed again.
func (s *fakeStorage) setFailing(fail bool) {
	s.mu.Lock()
	defer s.mu.Unlock()

	s.fail = fail
}

func (s *fakeStorage) failing() bool {
	s.mu.Lock()
	defer s.mu.Unlock()

	return s.fail
}

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
