// @date 2026-09-20
// @file user_profile.go
// @brief DTO mapping the user_profiles row to the model.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>, DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package dto

import (
	"time"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"uuid"
)

type UserProfile struct {
	UserID          uuid.UUID            `db:"user_id"`
	BirthDate       *time.Time           `db:"birth_date"`
	HeightCM        *uint16              `db:"height_cm"`
	WeightKG        *float32             `db:"weight_kg"`
	ArmSpanCM       *uint16              `db:"arm_span_cm"`
	DominantHand    *model.DominantHand  `db:"dominant_hand"`
	ClimbingLevel   *string              `db:"climbing_level"`
	GradingSystem   *model.GradingSystem `db:"grading_system"`
	YearsOfPractice *uint8               `db:"years_of_practice"`
	Bio             *string              `db:"bio"`
	AvatarObjectKey *string              `db:"avatar_object_key"`
	CreatedAt       *time.Time           `db:"created_at"`
	UpdatedAt       *time.Time           `db:"updated_at"`
}

func (u UserProfile) ToUserProfile() model.UserProfile {
	return model.UserProfile{
		UserID:          u.UserID,
		BirthDate:       u.BirthDate,
		HeightCM:        u.HeightCM,
		WeightKG:        u.WeightKG,
		ArmSpanCM:       u.ArmSpanCM,
		DominantHand:    u.DominantHand,
		ClimbingLevel:   u.ClimbingLevel,
		GradingSystem:   u.GradingSystem,
		YearsOfPratice:  u.YearsOfPractice,
		Bio:             u.Bio,
		AvatarObjectKey: u.AvatarObjectKey,
		CreatedAt:       u.CreatedAt,
		UpdatedAt:       u.UpdatedAt,
	}
}
