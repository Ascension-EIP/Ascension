// @date 2026-11-13
// @file user_profile_test.go
// @brief Unit tests of the user profile update request DTO.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package request

import (
	"github.com/Ascension-EIP/Ascension/apps/server/internal/testutil/knownbug"
	"testing"
	"time"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"uuid"
)

func decodeProfileUpdate(t *testing.T, body string) *UpdateUserProfile {
	t.Helper()

	var req UpdateUserProfile
	if err := bindJSON(body, &req); err != nil {
		t.Fatalf("bind(%s) error = %v", body, err)
	}
	return &req
}

func TestUpdateUserProfileIntoPartial(t *testing.T) {
	userID := uuid.NewV7()

	t.Run("absent fields stay unchanged", func(t *testing.T) {
		partial := decodeProfileUpdate(t, `{}`).IntoPartial(userID)
		if partial != (model.UserProfilePartial{UserID: userID}) {
			t.Errorf("IntoPartial() = %+v, want only the user ID", partial)
		}
	})

	t.Run("every field is set", func(t *testing.T) {
		req := decodeProfileUpdate(t, `{
			"birth_date": "1998-04-02T00:00:00Z",
			"height_cm": 178,
			"weight_kg": 68.5,
			"arm_span_cm": 182,
			"dominant_hand": "left",
			"climbing_level": "7a",
			"grading_system": "font",
			"years_of_practice": 6,
			"bio": "Boulder addict",
			"avatar_object_key": "avatars/a.png"
		}`)
		partial := req.IntoPartial(userID)

		if partial.UserID != userID {
			t.Errorf("UserID = %v, want %v", partial.UserID, userID)
		}
		if got := **partial.BirthDate; !got.Equal(time.Date(1998, 4, 2, 0, 0, 0, 0, time.UTC)) {
			t.Errorf("BirthDate = %v", got)
		}
		if **partial.HeightCM != 178 || **partial.WeightKG != 68.5 || **partial.ArmSpanCM != 182 {
			t.Errorf("height/weight/armspan = %v %v %v", **partial.HeightCM, **partial.WeightKG, **partial.ArmSpanCM)
		}
		if **partial.DominantHand != model.DominantHandLeft || **partial.GradingSystem != model.GradingSystemFont {
			t.Errorf("hand/grading = %v %v", **partial.DominantHand, **partial.GradingSystem)
		}
		if **partial.ClimbingLevel != "7a" || **partial.YearsOfPratice != 6 || **partial.Bio != "Boulder addict" || **partial.AvatarObjectKey != "avatars/a.png" {
			t.Errorf("level/years/bio/avatar = %v %v %v %v", **partial.ClimbingLevel, **partial.YearsOfPratice, **partial.Bio, **partial.AvatarObjectKey)
		}
		if err := partial.Validate(); err != nil {
			t.Errorf("Validate() = %v, want nil", err)
		}
	})

	t.Run("built partials set every field", func(t *testing.T) {
		req := UpdateUserProfile{
			BirthDate:       new(new(time.Date(1998, 4, 2, 0, 0, 0, 0, time.UTC))),
			HeightCM:        new(new(uint16(178))),
			WeightKG:        new(new(float32(68))),
			ArmSpanCM:       new(new(uint16(180))),
			DominantHand:    new(new(model.DominantHandRight)),
			ClimbingLevel:   new(new("6c")),
			GradingSystem:   new(new(model.GradingSystemYDS)),
			YearsOfPratice:  new(new(uint8(2))),
			Bio:             new(new("bio")),
			AvatarObjectKey: new(new("key")),
		}
		partial := req.IntoPartial(userID)
		if partial.BirthDate == nil || partial.HeightCM == nil || partial.WeightKG == nil || partial.ArmSpanCM == nil ||
			partial.DominantHand == nil || partial.ClimbingLevel == nil || partial.GradingSystem == nil ||
			partial.YearsOfPratice == nil || partial.Bio == nil || partial.AvatarObjectKey == nil {
			t.Fatalf("IntoPartial() = %+v, want every field set", partial)
		}
	})

	t.Run("null clears the field", func(t *testing.T) {
		knownbug.Skip(t, "encoding/json decodes null into a nil **T, so a profile field can never be cleared (use request.Optional)")

		partial := decodeProfileUpdate(t, `{"bio": null, "height_cm": null}`).IntoPartial(userID)
		if partial.Bio == nil || *partial.Bio != nil {
			t.Errorf("Bio = %v, want a pointer to nil", partial.Bio)
		}
		if partial.HeightCM == nil || *partial.HeightCM != nil {
			t.Errorf("HeightCM = %v, want a pointer to nil", partial.HeightCM)
		}
	})
}
