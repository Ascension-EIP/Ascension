// @date 2026-09-20
// @file user_profile.go
// @brief HTTP request DTO for profile edits.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>, DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package request

import (
	"time"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"uuid"
)

type UpdateUserProfile struct {
	BirthDate       **time.Time           `json:"birth_date"`
	HeightCM        **uint16              `json:"height_cm"`
	WeightKG        **float32             `json:"weight_kg"`
	ArmSpanCM       **uint16              `json:"arm_span_cm"`
	DominantHand    **model.DominantHand  `json:"dominant_hand"`
	ClimbingLevel   **string              `json:"climbing_level"`
	GradingSystem   **model.GradingSystem `json:"grading_system"`
	YearsOfPratice  **uint8               `json:"years_of_practice"`
	Bio             **string              `json:"bio"`
	AvatarObjectKey **string              `json:"avatar_object_key"`
}

func (req *UpdateUserProfile) IntoPartial(userID uuid.UUID) model.UserProfilePartial {
	partial := model.UserProfilePartial{UserID: userID}

	if req.BirthDate != nil {
		birthDate := *req.BirthDate
		partial.BirthDate = &birthDate
	}
	if req.HeightCM != nil {
		height := *req.HeightCM
		partial.HeightCM = &height
	}
	if req.WeightKG != nil {
		weight := *req.WeightKG
		partial.WeightKG = &weight
	}
	if req.ArmSpanCM != nil {
		armspan := *req.ArmSpanCM
		partial.ArmSpanCM = &armspan
	}
	if req.DominantHand != nil {
		hand := *req.DominantHand
		partial.DominantHand = &hand
	}
	if req.ClimbingLevel != nil {
		level := *req.ClimbingLevel
		partial.ClimbingLevel = &level
	}
	if req.GradingSystem != nil {
		system := *req.GradingSystem
		partial.GradingSystem = &system
	}
	if req.YearsOfPratice != nil {
		years := *req.YearsOfPratice
		partial.YearsOfPratice = &years
	}
	if req.Bio != nil {
		bio := *req.Bio
		partial.Bio = &bio
	}
	if req.AvatarObjectKey != nil {
		key := *req.AvatarObjectKey
		partial.AvatarObjectKey = &key
	}

	return partial
}
