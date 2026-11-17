// @date 2026-11-14
// @file list_errors_test.go
// @brief Endpoint tests of the video and analysis lists when the query or the repository fails, and of the advice retry.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package router

import (
	"context"
	"errors"
	"net/http"
	"testing"

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/testutil/memrepo"
)

// errListFailed is returned by failingListRepo for every list query.
var errListFailed = errors.New("list query failed")

// failingListRepo is a memrepo.Repo whose video and analysis lists always fail, as a lost database would.
type failingListRepo struct {
	*memrepo.Repo
}

func (failingListRepo) ListVideosByFilter(context.Context, model.VideoFilter, model.Pagination) ([]model.Video, error) {
	return nil, errListFailed
}

func (failingListRepo) ListAnalysisSummariesByUserID(context.Context, uuid.UUID, model.Pagination) ([]model.AnalysisSummary, int, error) {
	return nil, 0, errListFailed
}

func TestListsAnswer500WhenTheRepositoryFails(t *testing.T) {
	api := newTestAPI(t, failingListRepo{memrepo.New()})
	token := api.token(uuid.NewV7())

	for _, path := range []string{"/v1/videos/", "/v1/analysis"} {
		var body struct {
			Error string `json:"error"`
		}
		expect(t, api.do(http.MethodGet, path, token, nil), http.StatusInternalServerError, &body)
		if body.Error == "" {
			t.Errorf("GET %s: empty error message", path)
		}
	}
}

func TestListAnalysesRejectsAMalformedQuery(t *testing.T) {
	api := newTestAPI(t, memrepo.New())
	token := api.token(uuid.NewV7())

	for _, query := range []string{"limit=abc", "offset=abc"} {
		expect(t, api.do(http.MethodGet, "/v1/analysis?"+query, token, nil), http.StatusBadRequest, nil)
	}
}

// TestRetryAdviceOfAFailedAdviceSucceeds tests retrying the advice of
// a failed advice, which must succeed.
func TestRetryAdviceOfAFailedAdviceSucceeds(t *testing.T) {
	repo := memrepo.New()
	api := newTestAPI(t, repo)
	userID := uuid.NewV7()
	token := api.token(userID)
	video := putCompletedVideo(repo, userID)

	expect(t, api.do(http.MethodPost, "/v1/advices/"+video.ID.String(), token, nil), http.StatusAccepted, nil)
	failedErr := "worker crashed"
	pFailedErr := &failedErr
	if _, err := repo.UpdateAdvice(context.Background(), model.AdvicePartial{
		ID: video.ID, Status: new(model.JobStatusFailed), Error: &pFailedErr,
	}); err != nil {
		t.Fatalf("mark the advice failed: %v", err)
	}

	rec := api.do(http.MethodPost, "/v1/advices/"+video.ID.String()+"/retry", token, nil)
	if rec.Code < 200 || rec.Code > 299 {
		t.Errorf("retry of a failed advice: status %d, want 2xx (body %s)", rec.Code, rec.Body.String())
	}
}
