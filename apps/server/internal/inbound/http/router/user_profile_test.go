// @date 2026-11-13
// @file user_profile_test.go
// @brief Endpoint tests of GET and PUT /v1/profile through the real router, with an in-memory repository.
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

	"github.com/Ascension-EIP/Ascension/apps/server/internal/testutil/memrepo"
)

type profileBody struct {
	UserID          uuid.UUID  `json:"user_id"`
	BirthDate       *time.Time `json:"birth_date"`
	HeightCM        *uint16    `json:"height_cm"`
	WeightKG        *float32   `json:"weight_kg"`
	ArmSpanCM       *uint16    `json:"arm_span_cm"`
	DominantHand    *string    `json:"dominant_hand"`
	ClimbingLevel   *string    `json:"climbing_level"`
	GradingSystem   *string    `json:"grading_system"`
	YearsOfPratice  *uint8     `json:"years_of_practice"`
	Bio             *string    `json:"bio"`
	AvatarObjectKey *string    `json:"avatar_object_key"`
}

func TestProfileEndpointsRequireAuthentication(t *testing.T) {
	for _, method := range []string{http.MethodGet, http.MethodPut} {
		api := newTestAPI(t, memrepo.New())
		expect(t, api.do(method, "/v1/profile", "", nil), http.StatusUnauthorized, nil)
		expect(t, api.do(method, "/v1/profile", "not-a-jwt", nil), http.StatusUnauthorized, nil)
	}
}

func TestProfileLifecycle(t *testing.T) {
	api := newTestAPI(t, memrepo.New())
	registered := api.register("climber1")
	token := registered.AccessToken

	var profile profileBody
	expect(t, api.do(http.MethodGet, "/v1/profile", token, nil), http.StatusOK, &profile)
	if profile.UserID != registered.User.ID || profile.HeightCM != nil || profile.Bio != nil {
		t.Fatalf("new profile = %+v, want an empty profile of the user", profile)
	}

	update := map[string]any{
		"birth_date":        "1995-06-01T00:00:00Z",
		"height_cm":         178,
		"weight_kg":         68.5,
		"arm_span_cm":       182,
		"dominant_hand":     "left",
		"climbing_level":    "7a",
		"grading_system":    "french",
		"years_of_practice": 8,
		"bio":               "Crimps all day",
		"avatar_object_key": "avatars/climber1.png",
	}
	var updated profileBody
	expect(t, api.do(http.MethodPut, "/v1/profile", token, update), http.StatusOK, &updated)

	switch {
	case updated.HeightCM == nil || *updated.HeightCM != 178,
		updated.WeightKG == nil || *updated.WeightKG != 68.5,
		updated.ArmSpanCM == nil || *updated.ArmSpanCM != 182,
		updated.DominantHand == nil || *updated.DominantHand != "left",
		updated.ClimbingLevel == nil || *updated.ClimbingLevel != "7a",
		updated.GradingSystem == nil || *updated.GradingSystem != "french",
		updated.YearsOfPratice == nil || *updated.YearsOfPratice != 8,
		updated.Bio == nil || *updated.Bio != "Crimps all day",
		updated.AvatarObjectKey == nil || *updated.AvatarObjectKey != "avatars/climber1.png",
		updated.BirthDate == nil || !updated.BirthDate.Equal(time.Date(1995, 6, 1, 0, 0, 0, 0, time.UTC)):
		t.Fatalf("updated = %+v, want every field set", updated)
	}

	// A partial update leaves the other fields unchanged.
	var partial profileBody
	expect(t, api.do(http.MethodPut, "/v1/profile", token, map[string]any{"height_cm": 180}), http.StatusOK, &partial)
	if *partial.HeightCM != 180 || partial.Bio == nil || *partial.Bio != "Crimps all day" {
		t.Errorf("partial = %+v, want only the height changed", partial)
	}

	var got profileBody
	expect(t, api.do(http.MethodGet, "/v1/profile", token, nil), http.StatusOK, &got)
	if *got.HeightCM != 180 {
		t.Errorf("GET after update: height = %d, want 180", *got.HeightCM)
	}
}

func TestProfileInvalidBodies(t *testing.T) {
	api := newTestAPI(t, memrepo.New())
	token := api.register("climber1").AccessToken

	for _, body := range []any{"{", map[string]any{"height_cm": "tall"}, map[string]any{"height_cm": -1}} {
		expect(t, api.do(http.MethodPut, "/v1/profile", token, body), http.StatusBadRequest, nil)
	}
}

func TestProfileOfUserWithoutProfile(t *testing.T) {
	knownBug(t, "model.ErrNotFound is not mapped by utils.Error: GET /v1/profile of a user without profile answers 500 instead of 404")

	api := newTestAPI(t, memrepo.New())
	expect(t, api.do(http.MethodGet, "/v1/profile", api.token(uuid.NewV7()), nil), http.StatusNotFound, nil)
}

func TestProfileRejectsOutOfRangeValues(t *testing.T) {
	knownBug(t, "UserProfileService.UpdateUserProfile never calls UserProfilePartial.Validate: out of range values are stored (200 instead of 422)")

	api := newTestAPI(t, memrepo.New())
	token := api.register("climber1").AccessToken

	for _, body := range []map[string]any{{"height_cm": 10}, {"dominant_hand": "both"}, {"grading_system": "unknown"}, {"birth_date": "1800-01-01T00:00:00Z"}} {
		expect(t, api.do(http.MethodPut, "/v1/profile", token, body), http.StatusUnprocessableEntity, nil)
	}
}

func TestProfileNullClearsAField(t *testing.T) {
	knownBug(t, "request.UpdateUserProfile uses **T fields: encoding/json decodes null like an absent field, so null cannot clear a value (500)")

	api := newTestAPI(t, memrepo.New())
	token := api.register("climber1").AccessToken
	expect(t, api.do(http.MethodPut, "/v1/profile", token, map[string]any{"bio": "Crimps all day"}), http.StatusOK, nil)

	var cleared profileBody
	expect(t, api.do(http.MethodPut, "/v1/profile", token, `{"bio": null}`), http.StatusOK, &cleared)
	if cleared.Bio != nil {
		t.Errorf("bio = %q, want null", *cleared.Bio)
	}
}
