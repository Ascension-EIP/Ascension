// @date 2026-09-20
// @file user_profile.go
// @brief HTTP response DTO for a user profile.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>, DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package response

import (
	"time"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
)

type UserProfile struct {
	UserID          string     `json:"user_id"`
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

func UserProfileToResponse(userProfile model.UserProfile) UserProfile {
	var dominantHand *string
	if userProfile.DominantHand != nil {
		dominantHand = new(string(*userProfile.DominantHand))
	}
	var gradingSystem *string
	if userProfile.GradingSystem != nil {
		gradingSystem = new(string(*userProfile.GradingSystem))
	}

	return UserProfile{
		UserID:          userProfile.UserID.String(),
		BirthDate:       userProfile.BirthDate,
		HeightCM:        userProfile.HeightCM,
		WeightKG:        userProfile.WeightKG,
		ArmSpanCM:       userProfile.ArmSpanCM,
		DominantHand:    dominantHand,
		ClimbingLevel:   userProfile.ClimbingLevel,
		GradingSystem:   gradingSystem,
		YearsOfPratice:  userProfile.YearsOfPratice,
		Bio:             userProfile.Bio,
		AvatarObjectKey: userProfile.AvatarObjectKey,
	}
}
