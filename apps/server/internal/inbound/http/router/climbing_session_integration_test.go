// @date 2026-11-12
// @file climbing_session_integration_test.go
// @brief End-to-end tests of /v1/sessions and GET /v1/analysis: real router, services and PostgreSQL database.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package router

import (
	"context"
	"net/http"
	"testing"

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/testutil/pgtest"
)

func TestClimbingSessionEndpointsWithPostgres(t *testing.T) {
	db := pgtest.Open(t)
	userID, otherID := db.CreateUser(t), db.CreateUser(t)
	// One API per block of requests: each one allows 10 requests per minute and per group.
	api := newTestAPI(t, db.Repo)
	token, otherToken := api.token(userID), api.token(otherID)

	expect(t, api.do(http.MethodGet, "/v1/sessions/active", token, nil), http.StatusNoContent, nil)

	var created sessionBody
	expect(t, api.do(http.MethodPost, "/v1/sessions", token, map[string]any{
		"title": "Climb Up Gerland", "started_at": "2026-11-12T18:00:00Z", "visibility": "public",
	}), http.StatusCreated, &created)
	path := "/v1/sessions/" + created.ID.String()

	// A video uploaded in the session, and a standalone one added to the session afterwards.
	inSession := createAnalysis(t, db, db.CreateVideo(t, userID, &created.ID))
	standaloneVideo := db.CreateVideo(t, userID, nil)
	standalone := createAnalysis(t, db, standaloneVideo)
	othersAnalysis := createAnalysis(t, db, db.CreateVideo(t, otherID, nil))

	var active sessionBody
	expect(t, api.do(http.MethodGet, "/v1/sessions/active", token, nil), http.StatusOK, &active)
	if active.ID != created.ID || len(active.Analyses) != 1 || active.Analyses[0].ID != inSession {
		t.Fatalf("active = %+v, want the session with analysis %v", active, inSession)
	}

	expect(t, api.do(http.MethodPost, path+"/analyses", token, map[string]any{"analysis_id": standalone}), http.StatusNoContent, nil)
	expect(t, api.do(http.MethodPost, path+"/analyses", token, map[string]any{"analysis_id": othersAnalysis}), http.StatusNotFound, nil)
	expect(t, api.do(http.MethodPost, path+"/analyses", otherToken, map[string]any{"analysis_id": othersAnalysis}), http.StatusNotFound, nil)

	var details sessionBody
	expect(t, api.do(http.MethodGet, path, token, nil), http.StatusOK, &details)
	if details.Title == nil || *details.Title != "Climb Up Gerland" || details.Visibility != "public" {
		t.Fatalf("details = %+v", details)
	}
	got := map[uuid.UUID]bool{}
	for _, analysis := range details.Analyses {
		got[analysis.ID] = analysis.ClimbingSessionID != nil && *analysis.ClimbingSessionID == created.ID
	}
	if len(got) != 2 || !got[inSession] || !got[standalone] {
		t.Fatalf("details.Analyses = %+v, want analyses %v and %v in the session", details.Analyses, inSession, standalone)
	}

	api = newTestAPI(t, db.Repo)

	var list sessionListBody
	expect(t, api.do(http.MethodGet, "/v1/sessions?limit=5", token, nil), http.StatusOK, &list)
	if list.Total != 1 || list.Limit != 5 || len(list.Sessions) != 1 || list.Sessions[0].ID != created.ID {
		t.Fatalf("list = %+v", list)
	}

	var analyses analysisListBody
	expect(t, api.do(http.MethodGet, "/v1/analysis", token, nil), http.StatusOK, &analyses)
	if analyses.Total != 2 || len(analyses.Analyses) != 2 {
		t.Fatalf("analyses = %+v, want the 2 analyses of the user", analyses)
	}

	expect(t, api.do(http.MethodGet, path, otherToken, nil), http.StatusNotFound, nil)

	var ended sessionBody
	expect(t, api.do(http.MethodPut, path, token, map[string]any{"ended_at": "2026-11-12T21:00:00Z", "notes": "Sent the orange 6b"}), http.StatusOK, &ended)
	if ended.EndedAt == nil || ended.Notes == nil || *ended.Notes != "Sent the orange 6b" {
		t.Fatalf("ended = %+v", ended)
	}
	expect(t, api.do(http.MethodGet, "/v1/sessions/active", token, nil), http.StatusNoContent, nil)
	expect(t, api.do(http.MethodPut, path, token, map[string]any{"ended_at": "2026-11-12T17:00:00Z"}), http.StatusUnprocessableEntity, nil)

	var reopened sessionBody
	expect(t, api.do(http.MethodPut, path, token, map[string]any{"ended_at": nil}), http.StatusOK, &reopened)
	if reopened.EndedAt != nil {
		t.Fatalf("reopened.EndedAt = %v, want null", reopened.EndedAt)
	}

	expect(t, api.do(http.MethodDelete, path, otherToken, nil), http.StatusNotFound, nil)
	expect(t, api.do(http.MethodDelete, path, token, nil), http.StatusNoContent, nil)

	api = newTestAPI(t, db.Repo)
	expect(t, api.do(http.MethodGet, path, token, nil), http.StatusNotFound, nil)

	// Deleting a session keeps its videos and analyses, unlinked.
	expect(t, api.do(http.MethodGet, "/v1/analysis", token, nil), http.StatusOK, &analyses)
	if analyses.Total != 2 {
		t.Fatalf("analyses after delete: total = %d, want 2", analyses.Total)
	}
	for _, analysis := range analyses.Analyses {
		if analysis.ClimbingSessionID != nil {
			t.Errorf("analysis %v still in session %v after delete", analysis.ID, *analysis.ClimbingSessionID)
		}
	}
}

func createAnalysis(t *testing.T, db pgtest.DB, videoID uuid.UUID) uuid.UUID {
	t.Helper()

	analysis, err := db.Repo.CreateAnalysis(context.Background(), model.Analysis{VideoID: videoID, Type: model.AnalysisType2D, Visibility: model.VisibilityPrivate})
	if err != nil {
		t.Fatalf("CreateAnalysis() error = %v", err)
	}

	return analysis.ID
}
