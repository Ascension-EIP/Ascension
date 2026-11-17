// @date 2026-11-16
// @file advice_test.go
// @brief Endpoint tests of POST /v1/advices/:id, GET /v1/advices/:id and POST /v1/advices/:id/retry through the real router.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package router

import (
	"context"
	"encoding/json"
	"net/http"
	"testing"

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/shared"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/testutil/memrepo"
)

type adviceBody struct {
	ID       uuid.UUID `json:"id"`
	Status   string    `json:"status"`
	Progress int16     `json:"progress"`
}

func TestAdviceEndpointsRequireAuthentication(t *testing.T) {
	id := uuid.NewV7().String()
	routes := []struct{ method, path string }{
		{http.MethodPost, "/v1/advices/" + id},
		{http.MethodGet, "/v1/advices/" + id},
		{http.MethodPost, "/v1/advices/" + id + "/retry"},
	}

	for _, route := range routes {
		t.Run(route.method+" "+route.path, func(t *testing.T) {
			api := newTestAPI(t, memrepo.New())
			expect(t, api.do(route.method, route.path, "", nil), http.StatusUnauthorized, nil)
			expect(t, api.do(route.method, route.path, "not-a-jwt", nil), http.StatusUnauthorized, nil)
		})
	}
}

func TestAdviceEndpointsInvalidID(t *testing.T) {
	api := newTestAPI(t, memrepo.New())
	token := api.token(uuid.NewV7())

	expect(t, api.do(http.MethodPost, "/v1/advices/not-a-uuid", token, nil), http.StatusBadRequest, nil)
	expect(t, api.do(http.MethodGet, "/v1/advices/not-a-uuid", token, nil), http.StatusBadRequest, nil)
	expect(t, api.do(http.MethodPost, "/v1/advices/not-a-uuid/retry", token, nil), http.StatusBadRequest, nil)
}

func TestTriggerAndGetAdvice(t *testing.T) {
	repo := memrepo.New()
	api := newTestAPI(t, repo)
	userID := uuid.NewV7()
	token := api.token(userID)
	video := putCompletedVideo(repo, userID)

	var created adviceBody
	expect(t, api.do(http.MethodPost, "/v1/advices/"+video.ID.String(), token, nil), http.StatusAccepted, &created)
	if created.ID != video.ID || created.Status != string(model.JobStatusPending) {
		t.Fatalf("created = %+v, want a pending advice with video ID", created)
	}

	published := api.queue.published()
	if len(published) != 1 {
		t.Fatalf("%d jobs published, want 1", len(published))
	}
	var job shared.Job
	if err := json.Unmarshal(published[0], &job); err != nil {
		t.Fatalf("Unmarshal(job) error = %v", err)
	}
	if job.JobID != video.ID.String() {
		t.Errorf("job = %+v, want job ID to be video ID", job)
	}

	var got adviceBody
	expect(t, api.do(http.MethodGet, "/v1/advices/"+video.ID.String(), token, nil), http.StatusOK, &got)
	if got != created {
		t.Errorf("GET = %+v, want %+v", got, created)
	}
}

func TestRetryAdvice(t *testing.T) {
	repo := memrepo.New()
	api := newTestAPI(t, repo)
	userID := uuid.NewV7()
	token := api.token(userID)
	video := putCompletedVideo(repo, userID)

	// Trigger advice
	expect(t, api.do(http.MethodPost, "/v1/advices/"+video.ID.String(), token, nil), http.StatusAccepted, nil)

	// Retry before failure should fail (status is still pending)
	expect(t, api.do(http.MethodPost, "/v1/advices/"+video.ID.String()+"/retry", token, nil), http.StatusInternalServerError, nil)

	// Mark advice failed
	failedErr := "worker crashed"
	pFailedErr := &failedErr
	if _, err := repo.UpdateAdvice(context.Background(), model.AdvicePartial{
		ID: video.ID, Status: new(model.JobStatusFailed), Error: &pFailedErr,
	}); err != nil {
		t.Fatalf("mark the advice failed: %v", err)
	}

	var retried adviceBody
	expect(t, api.do(http.MethodPost, "/v1/advices/"+video.ID.String()+"/retry", token, nil), http.StatusAccepted, &retried)
	if retried.ID != video.ID || retried.Status != string(model.JobStatusPending) {
		t.Errorf("retried = %+v, want pending status and video ID", retried)
	}
}

func TestAdviceEndpointsNotFound(t *testing.T) {
	repo := memrepo.New()
	api := newTestAPI(t, repo)
	token := api.token(uuid.NewV7())
	id := uuid.NewV7().String()

	expect(t, api.do(http.MethodGet, "/v1/advices/"+id, token, nil), http.StatusInternalServerError, nil)
	expect(t, api.do(http.MethodPost, "/v1/advices/"+id, token, nil), http.StatusInternalServerError, nil)
	expect(t, api.do(http.MethodPost, "/v1/advices/"+id+"/retry", token, nil), http.StatusInternalServerError, nil)
}
