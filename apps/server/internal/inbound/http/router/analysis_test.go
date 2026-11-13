// @date 2026-11-13
// @file analysis_test.go
// @brief Endpoint tests of POST /v1/analysis, GET /v1/analysis/:id and retry-advice through the real router.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package router

import (
	"encoding/json"
	"errors"
	"net/http"
	"testing"

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/shared"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/testutil/memrepo"
)

type analysisBody struct {
	ID         uuid.UUID `json:"id"`
	VideoID    uuid.UUID `json:"video_id"`
	Type       string    `json:"type"`
	Status     string    `json:"status"`
	Visibility string    `json:"visibility"`
	Progress   int16     `json:"progress"`
}

func analysisRequest(videoID uuid.UUID) map[string]any {
	return map[string]any{"video_id": videoID, "type": "2d", "visibility": "friends"}
}

func TestAnalysisEndpointsRequireAuthentication(t *testing.T) {
	id := uuid.NewV7().String()
	routes := []struct{ method, path string }{
		{http.MethodPost, "/v1/analysis/"},
		{http.MethodGet, "/v1/analysis/" + id},
		{http.MethodPost, "/v1/analysis/" + id + "/retry-advice"},
	}

	for _, route := range routes {
		t.Run(route.method+" "+route.path, func(t *testing.T) {
			api := newTestAPI(t, memrepo.New())
			expect(t, api.do(route.method, route.path, "", nil), http.StatusUnauthorized, nil)
			expect(t, api.do(route.method, route.path, "not-a-jwt", nil), http.StatusUnauthorized, nil)
		})
	}
}

func TestCreateAndGetAnalysis(t *testing.T) {
	repo := memrepo.New()
	api := newTestAPI(t, repo)
	userID := uuid.NewV7()
	token := api.token(userID)
	video := putCompletedVideo(repo, userID)

	var created analysisBody
	expect(t, api.do(http.MethodPost, "/v1/analysis/", token, analysisRequest(video.ID)), http.StatusAccepted, &created)
	if created.VideoID != video.ID || created.Type != "2d" || created.Visibility != "friends" || created.Status != string(model.JobStatusPending) {
		t.Fatalf("created = %+v, want a pending 2d analysis of the video", created)
	}

	published := api.queue.published()
	if len(published) != 1 {
		t.Fatalf("%d jobs published, want 1", len(published))
	}
	var job shared.PoseDetectRequest
	if err := json.Unmarshal(published[0], &job); err != nil {
		t.Fatalf("Unmarshal(job) error = %v", err)
	}
	if job.JobID != created.ID.String() || job.ObjectKey != video.ObjectKey {
		t.Errorf("job = %+v, want the analysis ID and the video object key", job)
	}

	var got analysisBody
	expect(t, api.do(http.MethodGet, "/v1/analysis/"+created.ID.String(), token, nil), http.StatusOK, &got)
	if got != created {
		t.Errorf("GET = %+v, want %+v", got, created)
	}
}

func TestCreateAnalysisInvalidBodies(t *testing.T) {
	videoID := uuid.NewV7()
	tests := []struct {
		name string
		body any
	}{
		{"not json", "{"},
		{"no body", nil},
		{"missing video", map[string]any{"type": "2d", "visibility": "private"}},
		{"missing type", map[string]any{"video_id": videoID, "visibility": "private"}},
		{"missing visibility", map[string]any{"video_id": videoID, "type": "2d"}},
		{"video not a uuid", map[string]any{"video_id": "abc", "type": "2d", "visibility": "private"}},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			api := newTestAPI(t, memrepo.New())
			expect(t, api.do(http.MethodPost, "/v1/analysis/", api.token(uuid.NewV7()), tt.body), http.StatusBadRequest, nil)
		})
	}
}

func TestCreateAnalysisQueueFailure(t *testing.T) {
	repo := memrepo.New()
	api := newTestAPI(t, repo)
	userID := uuid.NewV7()
	video := putCompletedVideo(repo, userID)
	api.queue.err = errors.New("broker down")

	expect(t, api.do(http.MethodPost, "/v1/analysis/", api.token(userID), analysisRequest(video.ID)), http.StatusInternalServerError, nil)
}

func TestCreateAnalysisRefusesOtherAndPendingVideos(t *testing.T) {
	repo := memrepo.New()
	api := newTestAPI(t, repo)
	userID := uuid.NewV7()
	token := api.token(userID)

	pending := putCompletedVideo(repo, userID)
	pending.Status = model.VideoStatusPending
	repo.PutVideo(pending)
	others := putCompletedVideo(repo, uuid.NewV7())

	for _, videoID := range []uuid.UUID{pending.ID, others.ID, uuid.NewV7()} {
		if rec := api.do(http.MethodPost, "/v1/analysis/", token, analysisRequest(videoID)); rec.Code < 400 {
			t.Errorf("analysis of video %v: status = %d, want an error", videoID, rec.Code)
		}
	}
	if got := len(api.queue.published()); got != 0 {
		t.Errorf("%d jobs published, want 0", got)
	}
}

func TestCreateAnalysisErrorStatuses(t *testing.T) {
	knownBug(t, "TriggerAnalysis errors are not mapped: invalid type 500 (want 422), pending video 500 (want 409), other user's video 500 (want 404)")

	repo := memrepo.New()
	api := newTestAPI(t, repo)
	userID := uuid.NewV7()
	token := api.token(userID)
	video := putCompletedVideo(repo, userID)

	body := analysisRequest(video.ID)
	body["type"] = "4d"
	expect(t, api.do(http.MethodPost, "/v1/analysis/", token, body), http.StatusUnprocessableEntity, nil)

	pending := putCompletedVideo(repo, userID)
	pending.Status = model.VideoStatusPending
	repo.PutVideo(pending)
	expect(t, api.do(http.MethodPost, "/v1/analysis/", token, analysisRequest(pending.ID)), http.StatusConflict, nil)

	others := putCompletedVideo(repo, uuid.NewV7())
	expect(t, api.do(http.MethodPost, "/v1/analysis/", token, analysisRequest(others.ID)), http.StatusNotFound, nil)
}

func TestGetAnalysisInvalidID(t *testing.T) {
	api := newTestAPI(t, memrepo.New())
	token := api.token(uuid.NewV7())

	expect(t, api.do(http.MethodGet, "/v1/analysis/not-a-uuid", token, nil), http.StatusBadRequest, nil)
	expect(t, api.do(http.MethodPost, "/v1/analysis/not-a-uuid/retry-advice", token, nil), http.StatusBadRequest, nil)
}

func TestGetUnknownAnalysis(t *testing.T) {
	knownBug(t, "model.ErrNotFound is not mapped by utils.Error: an unknown analysis answers 500 instead of 404")

	api := newTestAPI(t, memrepo.New())
	expect(t, api.do(http.MethodGet, "/v1/analysis/"+uuid.NewV7().String(), api.token(uuid.NewV7()), nil), http.StatusNotFound, nil)
}

func TestAnalysisOfAnotherUserIsHidden(t *testing.T) {
	knownBug(t, "AnalysisService.GetAnalysisByID never checks the owner: any user reads any analysis by ID (200 instead of 404)")

	repo := memrepo.New()
	api := newTestAPI(t, repo)
	ownerID := uuid.NewV7()
	video := putCompletedVideo(repo, ownerID)

	var created analysisBody
	expect(t, api.do(http.MethodPost, "/v1/analysis/", api.token(ownerID), analysisRequest(video.ID)), http.StatusAccepted, &created)
	expect(t, api.do(http.MethodGet, "/v1/analysis/"+created.ID.String(), api.token(uuid.NewV7()), nil), http.StatusNotFound, nil)
}

func TestRetryAdviceOfUnknownAnalysis(t *testing.T) {
	knownBug(t, "AnalysisService.RetryAdvice is a TODO: it answers 204 for any ID and retries nothing")

	api := newTestAPI(t, memrepo.New())
	expect(t, api.do(http.MethodPost, "/v1/analysis/"+uuid.NewV7().String()+"/retry-advice", api.token(uuid.NewV7()), nil), http.StatusNotFound, nil)
}
