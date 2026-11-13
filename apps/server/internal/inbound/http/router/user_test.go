// @date 2026-11-13
// @file user_test.go
// @brief Endpoint tests of the admin routes /v1/users through the real router, with an in-memory repository.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package router

import (
	"net/http"
	"testing"

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/testutil/memrepo"
)

func adminToken(api *testAPI) string {
	return api.tokenFor(model.User{ID: uuid.NewV7(), Username: "admin-user", Role: model.UserRoleAdmin})
}

func createUserBody(username string) map[string]any {
	return map[string]any{
		"username":   username,
		"first_name": "Lynn",
		"last_name":  "Hill",
		"email":      username + "@example.com",
		"password":   "correct-horse",
		"role":       "coach",
	}
}

func TestUserEndpointsRequireAnAdmin(t *testing.T) {
	id := uuid.NewV7().String()
	routes := []struct{ method, path string }{
		{http.MethodPost, "/v1/users/"},
		{http.MethodGet, "/v1/users/"},
		{http.MethodGet, "/v1/users/" + id},
		{http.MethodPut, "/v1/users/" + id},
		{http.MethodDelete, "/v1/users/" + id},
	}

	repo := memrepo.New()
	api := newTestAPI(t, repo)
	for _, role := range []model.UserRole{model.UserRoleUser, model.UserRoleCoach, model.UserRoleGym} {
		token := api.tokenFor(model.User{ID: uuid.NewV7(), Username: "not-admin", Role: role})
		for _, route := range routes {
			t.Run(string(role)+" "+route.method+" "+route.path, func(t *testing.T) {
				expect(t, api.do(route.method, route.path, "", createUserBody("climber1")), http.StatusUnauthorized, nil)
				expect(t, api.do(route.method, route.path, token, createUserBody("climber1")), http.StatusUnauthorized, nil)
			})
		}
	}

	// The handler never ran: nothing was created.
	users, _ := repo.ListUsersByFilter(t.Context(), model.UserFilter{})
	if len(users) != 0 {
		t.Errorf("%d users created by non admins, want 0", len(users))
	}
}

func TestUserAdminLifecycle(t *testing.T) {
	repo := memrepo.New()
	api := newTestAPI(t, repo)
	token := adminToken(api)

	var created userBody
	expect(t, api.do(http.MethodPost, "/v1/users/", token, createUserBody("climber1")), http.StatusCreated, &created)
	if created.Username != "climber1" || created.Role != "coach" || created.Status != string(model.UserStatusActive) {
		t.Fatalf("created = %+v, want an active coach climber1", created)
	}

	var got userBody
	expect(t, api.do(http.MethodGet, "/v1/users/"+created.ID.String(), token, nil), http.StatusOK, &got)
	if got != created {
		t.Errorf("GET = %+v, want %+v", got, created)
	}

	var list []userBody
	expect(t, api.do(http.MethodGet, "/v1/users/", token, nil), http.StatusOK, &list)
	if len(list) != 1 || list[0].ID != created.ID {
		t.Errorf("list = %+v, want the created user", list)
	}

	// Every field validated by UserPartial.Validate is given.
	update := map[string]any{
		"username": "climber2", "first_name": "Janja", "last_name": "Garnbret", "email": "Janja@Example.com",
		"password": "new-password", "role": "user", "status": "deactivated",
	}
	var updated userBody
	expect(t, api.do(http.MethodPut, "/v1/users/"+created.ID.String(), token, update), http.StatusOK, &updated)
	if updated.Username != "climber2" || updated.Email != "janja@example.com" || updated.Role != "user" || updated.Status != "deactivated" {
		t.Errorf("updated = %+v", updated)
	}

	expect(t, api.do(http.MethodDelete, "/v1/users/"+created.ID.String(), token, nil), http.StatusNoContent, nil)
	if _, ok := repo.User(created.ID); ok {
		t.Error("user still stored after DELETE")
	}
}

func TestUserAdminInvalidRequests(t *testing.T) {
	api := newTestAPI(t, memrepo.New())
	token := adminToken(api)

	expect(t, api.do(http.MethodPost, "/v1/users/", token, "{"), http.StatusBadRequest, nil)
	missing := createUserBody("climber1")
	delete(missing, "role")
	expect(t, api.do(http.MethodPost, "/v1/users/", token, missing), http.StatusBadRequest, nil)

	expect(t, api.do(http.MethodGet, "/v1/users/not-a-uuid", token, nil), http.StatusBadRequest, nil)
	expect(t, api.do(http.MethodPut, "/v1/users/not-a-uuid", token, map[string]any{}), http.StatusBadRequest, nil)
	expect(t, api.do(http.MethodPut, "/v1/users/"+uuid.NewV7().String(), token, "{"), http.StatusBadRequest, nil)
	expect(t, api.do(http.MethodDelete, "/v1/users/not-a-uuid", token, nil), http.StatusBadRequest, nil)
}

func TestUserAdminRejectsInvalidUser(t *testing.T) {
	knownBug(t, "user validation errors (unknown role, short username) do not wrap model.ErrInvalidInput: 500 instead of 422")

	api := newTestAPI(t, memrepo.New())
	token := adminToken(api)

	body := createUserBody("climber1")
	body["role"] = "superuser"
	expect(t, api.do(http.MethodPost, "/v1/users/", token, body), http.StatusUnprocessableEntity, nil)
}

func TestUserAdminUnknownUser(t *testing.T) {
	knownBug(t, "model.ErrNotFound from the repository is not mapped by utils.Error: GET /v1/users/:id answers 500 instead of 404")

	api := newTestAPI(t, memrepo.New())
	expect(t, api.do(http.MethodGet, "/v1/users/"+uuid.NewV7().String(), adminToken(api), nil), http.StatusNotFound, nil)
}

func TestUserAdminPartialUpdate(t *testing.T) {
	knownBug(t, "UserPartial.Validate calls Validate on nil pointers: a PUT without every field panics and answers 500")

	api := newTestAPI(t, memrepo.New())
	token := adminToken(api)

	var created userBody
	expect(t, api.do(http.MethodPost, "/v1/users/", token, createUserBody("climber1")), http.StatusCreated, &created)

	var updated userBody
	expect(t, api.do(http.MethodPut, "/v1/users/"+created.ID.String(), token, map[string]any{"first_name": "Janja"}), http.StatusOK, &updated)
	if updated.Username != "climber1" {
		t.Errorf("username = %q, want it unchanged", updated.Username)
	}
}
