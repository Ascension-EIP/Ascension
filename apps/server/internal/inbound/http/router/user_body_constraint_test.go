// @date 2026-11-13
// @file user_body_constraint_test.go
// @brief Endpoint tests of /v1/profile/constraints.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package router

import (
	"net/http"
	"testing"

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/testutil/memrepo"
)

type bodyConstraintBody struct {
	ID        uuid.UUID `json:"id"`
	Zone      string    `json:"zone"`
	Type      string    `json:"type"`
	Note      *string   `json:"note"`
	StartedAt string    `json:"started_at"`
	EndedAt   *string   `json:"ended_at"`
}

type bodyConstraintListBody struct {
	Constraints []bodyConstraintBody `json:"constraints"`
}

// testBodyConstraintEndpoints runs the body constraint scenario against a repository: memrepo
// in the unit test, PostgreSQL in the integration test.
func testBodyConstraintEndpoints(t *testing.T, repo testRepo, userID uuid.UUID, otherID uuid.UUID) {
	t.Helper()

	// One API per block of requests: each one allows 10 requests per minute and per group.
	api := newTestAPI(t, repo)
	token, otherToken := api.token(userID), api.token(otherID)

	expect(t, api.do(http.MethodGet, "/v1/profile/constraints", "", nil), http.StatusUnauthorized, nil)

	var empty bodyConstraintListBody
	expect(t, api.do(http.MethodGet, "/v1/profile/constraints", token, nil), http.StatusOK, &empty)
	if empty.Constraints == nil || len(empty.Constraints) != 0 {
		t.Fatalf("empty list = %+v, want []", empty)
	}

	var injury bodyConstraintBody
	expect(t, api.do(http.MethodPost, "/v1/profile/constraints", token,
		map[string]any{"zone": "left_knee", "type": "injured", "note": "Sprain", "started_at": "2026-10-01T00:00:00Z"}),
		http.StatusCreated, &injury)
	if injury.ID == (uuid.UUID{}) || injury.Zone != "left_knee" || injury.Type != "injured" || injury.EndedAt != nil || injury.StartedAt[:10] != "2026-10-01" {
		t.Fatalf("created = %+v", injury)
	}

	// Declaring the same zone again replaces the active constraint.
	var replaced bodyConstraintBody
	expect(t, api.do(http.MethodPost, "/v1/profile/constraints", token,
		map[string]any{"zone": "left_knee", "type": "injured", "note": "Better"}),
		http.StatusOK, &replaced)
	if replaced.ID != injury.ID || replaced.Note == nil || *replaced.Note != "Better" || replaced.StartedAt[:10] != "2026-10-01" {
		t.Fatalf("replaced = %+v, want the same constraint with the new note and the same start", replaced)
	}

	var missing bodyConstraintBody
	expect(t, api.do(http.MethodPost, "/v1/profile/constraints", token,
		map[string]any{"zone": "right_hand", "type": "missing"}),
		http.StatusCreated, &missing)

	// Validation: body shape (400), then values (422).
	expect(t, api.do(http.MethodPost, "/v1/profile/constraints", token, map[string]any{"zone": "neck"}), http.StatusBadRequest, nil)
	expect(t, api.do(http.MethodPost, "/v1/profile/constraints", token, map[string]any{"zone": "wing", "type": "injured"}), http.StatusUnprocessableEntity, nil)
	expect(t, api.do(http.MethodPost, "/v1/profile/constraints", token, map[string]any{"zone": "neck", "type": "injury"}), http.StatusUnprocessableEntity, nil)

	var list bodyConstraintListBody
	expect(t, api.do(http.MethodGet, "/v1/profile/constraints", token, nil), http.StatusOK, &list)
	if len(list.Constraints) != 2 || list.Constraints[0].Zone != "right_hand" || list.Constraints[1].Zone != "left_knee" {
		t.Fatalf("list = %+v, want right_hand then left_knee", list)
	}

	api = newTestAPI(t, repo)

	// Another user sees nothing and cannot remove the constraints.
	var otherList bodyConstraintListBody
	expect(t, api.do(http.MethodGet, "/v1/profile/constraints", otherToken, nil), http.StatusOK, &otherList)
	if len(otherList.Constraints) != 0 {
		t.Fatalf("another user's list = %+v, want empty", otherList)
	}
	expect(t, api.do(http.MethodDelete, "/v1/profile/constraints/"+injury.ID.String(), otherToken, nil), http.StatusNotFound, nil)

	expect(t, api.do(http.MethodDelete, "/v1/profile/constraints/not-a-uuid", token, nil), http.StatusBadRequest, nil)
	expect(t, api.do(http.MethodDelete, "/v1/profile/constraints/"+injury.ID.String(), token, nil), http.StatusNoContent, nil)
	expect(t, api.do(http.MethodDelete, "/v1/profile/constraints/"+injury.ID.String(), token, nil), http.StatusNotFound, nil)
	expect(t, api.do(http.MethodDelete, "/v1/profile/constraints/"+missing.ID.String(), token, nil), http.StatusNoContent, nil)

	var after bodyConstraintListBody
	expect(t, api.do(http.MethodGet, "/v1/profile/constraints", token, nil), http.StatusOK, &after)
	if len(after.Constraints) != 0 {
		t.Fatalf("list after removal = %+v, want empty", after)
	}
}

func TestBodyConstraintEndpoints(t *testing.T) {
	testBodyConstraintEndpoints(t, memrepo.New(), uuid.NewV7(), uuid.NewV7())
}
