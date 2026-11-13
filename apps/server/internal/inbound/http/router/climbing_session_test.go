// @date 2026-11-12
// @file climbing_session_test.go
// @brief Endpoint tests of /v1/sessions through the real router, with an in-memory repository.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package router

import (
	"net/http"
	"testing"
	"time"

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/testutil/memrepo"
)

func TestClimbingSessionEndpointsRequireAuthentication(t *testing.T) {
	repo := memrepo.New()
	id := uuid.NewV7()

	routes := []struct{ method, path string }{
		{http.MethodPost, "/v1/sessions"},
		{http.MethodGet, "/v1/sessions"},
		{http.MethodGet, "/v1/sessions/" + id.String()},
		{http.MethodPut, "/v1/sessions/" + id.String()},
		{http.MethodDelete, "/v1/sessions/" + id.String()},
		{http.MethodGet, "/v1/sessions/active"},
		{http.MethodPost, "/v1/sessions/" + id.String() + "/analyses"},
		{http.MethodGet, "/v1/analysis"},
	}

	for _, route := range routes {
		t.Run(route.method+" "+route.path, func(t *testing.T) {
			// A fresh API per route: the rate limiter runs before the authentication.
			api := newTestAPI(t, repo)
			expect(t, api.do(route.method, route.path, "", nil), http.StatusUnauthorized, nil)
			expect(t, api.do(route.method, route.path, "not-a-jwt", nil), http.StatusUnauthorized, nil)
		})
	}
}

func TestClimbingSessionEndpointsAreRateLimited(t *testing.T) {
	repo := memrepo.New()
	api := newTestAPI(t, repo)
	token := api.token(uuid.NewV7())

	for i := range 10 {
		if rec := api.do(http.MethodGet, "/v1/sessions", token, nil); rec.Code != http.StatusOK {
			t.Fatalf("request %d: status = %d, want 200", i+1, rec.Code)
		}
	}

	expect(t, api.do(http.MethodGet, "/v1/sessions", token, nil), http.StatusTooManyRequests, nil)
}

func TestClimbingSessionLifecycle(t *testing.T) {
	repo := memrepo.New()
	api := newTestAPI(t, repo)
	token := api.token(uuid.NewV7())

	var created sessionBody
	expect(t, api.do(http.MethodPost, "/v1/sessions", token, map[string]any{
		"title":      "Arkose Nation",
		"notes":      "Warm up on the slab",
		"started_at": "2026-11-12T18:00:00Z",
		"visibility": "friends",
	}), http.StatusCreated, &created)
	if created.Title == nil || *created.Title != "Arkose Nation" || created.Visibility != "friends" || created.EndedAt != nil {
		t.Fatalf("created = %+v", created)
	}
	path := "/v1/sessions/" + created.ID.String()

	var list sessionListBody
	expect(t, api.do(http.MethodGet, "/v1/sessions", token, nil), http.StatusOK, &list)
	if list.Total != 1 || len(list.Sessions) != 1 || list.Sessions[0].ID != created.ID || list.Limit != 20 || list.Offset != 0 {
		t.Fatalf("list = %+v", list)
	}

	var details sessionBody
	expect(t, api.do(http.MethodGet, path, token, nil), http.StatusOK, &details)
	if details.ID != created.ID || details.Analyses == nil || len(details.Analyses) != 0 {
		t.Fatalf("details = %+v, want the session with an empty analyses list", details)
	}

	var ended sessionBody
	expect(t, api.do(http.MethodPut, path, token, map[string]any{"ended_at": "2026-11-12T20:30:00Z", "notes": nil}), http.StatusOK, &ended)
	if ended.EndedAt == nil || !ended.EndedAt.Equal(time.Date(2026, 11, 12, 20, 30, 0, 0, time.UTC)) || ended.Notes != nil {
		t.Fatalf("ended = %+v, want ended_at set and notes cleared", ended)
	}
	if ended.Title == nil || *ended.Title != "Arkose Nation" {
		t.Fatalf("ended.Title = %v, want it unchanged", ended.Title)
	}

	expect(t, api.do(http.MethodDelete, path, token, nil), http.StatusNoContent, nil)
	expect(t, api.do(http.MethodGet, path, token, nil), http.StatusNotFound, nil)
	expect(t, api.do(http.MethodDelete, path, token, nil), http.StatusNotFound, nil)
}

func TestStartClimbingSessionWithoutBody(t *testing.T) {
	repo := memrepo.New()
	api := newTestAPI(t, repo)

	var created sessionBody
	before := time.Now().Add(-time.Second)
	expect(t, api.do(http.MethodPost, "/v1/sessions", api.token(uuid.NewV7()), nil), http.StatusCreated, &created)
	if created.Visibility != "private" || created.StartedAt.Before(before) || created.Title != nil {
		t.Fatalf("created = %+v, want a private session started now", created)
	}
}

func TestClimbingSessionsAreScopedToTheirOwner(t *testing.T) {
	repo := memrepo.New()
	api := newTestAPI(t, repo)
	owner, intruder := api.token(uuid.NewV7()), api.token(uuid.NewV7())

	var created sessionBody
	expect(t, api.do(http.MethodPost, "/v1/sessions", owner, map[string]any{"title": "Mine"}), http.StatusCreated, &created)
	path := "/v1/sessions/" + created.ID.String()

	var list sessionListBody
	expect(t, api.do(http.MethodGet, "/v1/sessions", intruder, nil), http.StatusOK, &list)
	if list.Total != 0 || len(list.Sessions) != 0 {
		t.Fatalf("intruder list = %+v, want empty", list)
	}

	expect(t, api.do(http.MethodGet, path, intruder, nil), http.StatusNotFound, nil)
	expect(t, api.do(http.MethodPut, path, intruder, map[string]any{"title": "Stolen"}), http.StatusNotFound, nil)
	expect(t, api.do(http.MethodDelete, path, intruder, nil), http.StatusNotFound, nil)

	var details sessionBody
	expect(t, api.do(http.MethodGet, path, owner, nil), http.StatusOK, &details)
	if details.Title == nil || *details.Title != "Mine" {
		t.Fatalf("owner details = %+v, want the title unchanged", details)
	}
}

func TestClimbingSessionPagination(t *testing.T) {
	repo := memrepo.New()
	api := newTestAPI(t, repo)
	token := api.token(uuid.NewV7())

	for i := range 3 {
		startedAt := time.Date(2026, 11, 10+i, 18, 0, 0, 0, time.UTC).Format(time.RFC3339)
		expect(t, api.do(http.MethodPost, "/v1/sessions", token, map[string]any{"started_at": startedAt}), http.StatusCreated, nil)
	}

	var page sessionListBody
	expect(t, api.do(http.MethodGet, "/v1/sessions?limit=2&offset=1", token, nil), http.StatusOK, &page)
	if page.Total != 3 || page.Limit != 2 || page.Offset != 1 || len(page.Sessions) != 2 {
		t.Fatalf("page = %+v", page)
	}
	if want := time.Date(2026, 11, 11, 18, 0, 0, 0, time.UTC); !page.Sessions[0].StartedAt.Equal(want) {
		t.Errorf("first session started at %v, want %v", page.Sessions[0].StartedAt, want)
	}
}

func TestClimbingSessionValidationErrors(t *testing.T) {
	repo := memrepo.New()
	api := newTestAPI(t, repo)
	token := api.token(uuid.NewV7())

	var created sessionBody
	expect(t, api.do(http.MethodPost, "/v1/sessions", token, map[string]any{"started_at": "2026-11-12T18:00:00Z"}), http.StatusCreated, &created)
	path := "/v1/sessions/" + created.ID.String()

	tests := []struct {
		name   string
		method string
		path   string
		body   any
		want   int
	}{
		{"malformed JSON", http.MethodPost, "/v1/sessions", `{"title":`, http.StatusBadRequest},
		{"unknown visibility", http.MethodPost, "/v1/sessions", map[string]any{"visibility": "everyone"}, http.StatusUnprocessableEntity},
		{"blank title", http.MethodPost, "/v1/sessions", map[string]any{"title": " "}, http.StatusUnprocessableEntity},
		{"invalid start time", http.MethodPost, "/v1/sessions", map[string]any{"started_at": "yesterday"}, http.StatusBadRequest},
		{"limit zero", http.MethodGet, "/v1/sessions?limit=0", nil, http.StatusBadRequest},
		{"limit too big", http.MethodGet, "/v1/sessions?limit=101", nil, http.StatusBadRequest},
		{"limit not a number", http.MethodGet, "/v1/sessions?limit=ten", nil, http.StatusBadRequest},
		{"negative offset", http.MethodGet, "/v1/sessions?offset=-1", nil, http.StatusBadRequest},
		{"get invalid id", http.MethodGet, "/v1/sessions/not-a-uuid", nil, http.StatusBadRequest},
		{"update invalid id", http.MethodPut, "/v1/sessions/not-a-uuid", map[string]any{}, http.StatusBadRequest},
		{"delete invalid id", http.MethodDelete, "/v1/sessions/not-a-uuid", nil, http.StatusBadRequest},
		{"get unknown id", http.MethodGet, "/v1/sessions/" + uuid.NewV7().String(), nil, http.StatusNotFound},
		{"update without body", http.MethodPut, path, nil, http.StatusBadRequest},
		{"end before start", http.MethodPut, path, map[string]any{"ended_at": "2026-11-12T17:00:00Z"}, http.StatusUnprocessableEntity},
		{"invalid end time", http.MethodPut, path, map[string]any{"ended_at": 12}, http.StatusBadRequest},
	}

	for i, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Each request uses a fresh API: the rate limiter allows 10 requests per minute.
			api := newTestAPI(t, repo)
			rec := api.do(tt.method, tt.path, token, tt.body)
			if rec.Code != tt.want {
				t.Fatalf("case %d: status = %d, want %d (body: %s)", i, rec.Code, tt.want, rec.Body.String())
			}
		})
	}

	var unchanged sessionBody
	expect(t, api.do(http.MethodPut, path, token, map[string]any{}), http.StatusOK, &unchanged)
	if unchanged.ID != created.ID || unchanged.EndedAt != nil {
		t.Fatalf("empty update = %+v, want the session unchanged", unchanged)
	}
}

func TestActiveClimbingSession(t *testing.T) {
	repo := memrepo.New()
	api := newTestAPI(t, repo)
	token := api.token(uuid.NewV7())

	rec := api.do(http.MethodGet, "/v1/sessions/active", token, nil)
	expect(t, rec, http.StatusNoContent, nil)
	if rec.Body.Len() != 0 {
		t.Fatalf("no active session: body = %q, want empty", rec.Body.String())
	}

	var created sessionBody
	expect(t, api.do(http.MethodPost, "/v1/sessions", token, map[string]any{"title": "Now"}), http.StatusCreated, &created)

	var active sessionBody
	expect(t, api.do(http.MethodGet, "/v1/sessions/active", token, nil), http.StatusOK, &active)
	if active.ID != created.ID || active.Analyses == nil {
		t.Fatalf("active = %+v, want session %v with an analyses list", active, created.ID)
	}

	expect(t, api.do(http.MethodPut, "/v1/sessions/"+created.ID.String(), token, map[string]any{"ended_at": time.Now().Add(time.Minute).Format(time.RFC3339)}), http.StatusOK, nil)
	expect(t, api.do(http.MethodGet, "/v1/sessions/active", token, nil), http.StatusNoContent, nil)
}

func TestAddAnalysisToClimbingSessionEndpoint(t *testing.T) {
	repo := memrepo.New()
	api := newTestAPI(t, repo)
	userID := uuid.NewV7()
	token, otherToken := api.token(userID), api.token(uuid.NewV7())

	var created sessionBody
	expect(t, api.do(http.MethodPost, "/v1/sessions", token, nil), http.StatusCreated, &created)
	path := "/v1/sessions/" + created.ID.String() + "/analyses"
	analysisID := putAnalysis(t, repo, userID, nil)

	expect(t, api.do(http.MethodPost, path, token, map[string]any{"analysis_id": analysisID}), http.StatusNoContent, nil)

	var details sessionBody
	expect(t, api.do(http.MethodGet, "/v1/sessions/"+created.ID.String(), token, nil), http.StatusOK, &details)
	if len(details.Analyses) != 1 || details.Analyses[0].ID != analysisID || details.Analyses[0].ClimbingSessionID == nil || *details.Analyses[0].ClimbingSessionID != created.ID {
		t.Fatalf("details.Analyses = %+v, want analysis %v in the session", details.Analyses, analysisID)
	}

	tests := []struct {
		name  string
		path  string
		token string
		body  any
		want  int
	}{
		{"missing analysis_id", path, token, map[string]any{}, http.StatusBadRequest},
		{"invalid analysis_id", path, token, map[string]any{"analysis_id": "nope"}, http.StatusBadRequest},
		{"invalid session id", "/v1/sessions/nope/analyses", token, map[string]any{"analysis_id": analysisID}, http.StatusBadRequest},
		{"unknown analysis", path, token, map[string]any{"analysis_id": uuid.NewV7()}, http.StatusNotFound},
		{"another user's session", path, otherToken, map[string]any{"analysis_id": analysisID}, http.StatusNotFound},
		{"unknown session", "/v1/sessions/" + uuid.NewV7().String() + "/analyses", token, map[string]any{"analysis_id": analysisID}, http.StatusNotFound},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			api := newTestAPI(t, repo)
			expect(t, api.do(http.MethodPost, tt.path, tt.token, tt.body), tt.want, nil)
		})
	}
}

func TestListAnalysesEndpoint(t *testing.T) {
	repo := memrepo.New()
	api := newTestAPI(t, repo)
	userID := uuid.NewV7()
	token := api.token(userID)

	var created sessionBody
	expect(t, api.do(http.MethodPost, "/v1/sessions", token, nil), http.StatusCreated, &created)
	inSession := putAnalysis(t, repo, userID, &created.ID)
	standalone := putAnalysis(t, repo, userID, nil)
	putAnalysis(t, repo, uuid.NewV7(), nil)

	var list analysisListBody
	expect(t, api.do(http.MethodGet, "/v1/analysis", token, nil), http.StatusOK, &list)
	if list.Total != 2 || len(list.Analyses) != 2 || list.Limit != 20 || list.Offset != 0 {
		t.Fatalf("list = %+v, want the 2 analyses of the user", list)
	}
	for _, analysis := range list.Analyses {
		switch analysis.ID {
		case inSession:
			if analysis.ClimbingSessionID == nil || *analysis.ClimbingSessionID != created.ID {
				t.Errorf("analysis in session: climbing_session_id = %v, want %v", analysis.ClimbingSessionID, created.ID)
			}
		case standalone:
			if analysis.ClimbingSessionID != nil {
				t.Errorf("standalone analysis: climbing_session_id = %v, want null", *analysis.ClimbingSessionID)
			}
		default:
			t.Errorf("unexpected analysis %v (another user's?)", analysis.ID)
		}
	}

	var page analysisListBody
	expect(t, api.do(http.MethodGet, "/v1/analysis?limit=1&offset=1", token, nil), http.StatusOK, &page)
	if page.Total != 2 || len(page.Analyses) != 1 || page.Limit != 1 || page.Offset != 1 {
		t.Fatalf("page = %+v", page)
	}

	expect(t, api.do(http.MethodGet, "/v1/analysis?limit=0", token, nil), http.StatusBadRequest, nil)
}

// putAnalysis stores a completed video of the user, optionally in a session, and an analysis of it.
func putAnalysis(t *testing.T, repo *memrepo.Repo, userID uuid.UUID, climbingSessionID *uuid.UUID) uuid.UUID {
	t.Helper()

	video := model.Video{ID: uuid.NewV7(), UserID: userID, ClimbingSessionID: climbingSessionID, ObjectKey: uuid.NewV7().String() + ".mp4", Status: model.VideoStatusCompleted}
	repo.PutVideo(video)

	analysis, err := repo.CreateAnalysis(t.Context(), model.Analysis{VideoID: video.ID, Type: model.AnalysisType2D, Visibility: model.VisibilityPrivate})
	if err != nil {
		t.Fatalf("CreateAnalysis() error = %v", err)
	}

	return analysis.ID
}
