// @date 2026-09-20
// @file user_profile.go
// @brief User profile repository: fetch and update user_profiles rows.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>, DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package postgres

import (
	"context"
	"fmt"
	"strings"
	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/outbound/postgres/dto"
	"github.com/jackc/pgx/v5"
)

func (r *PostgresRepository) CreateUserProfile(ctx context.Context, userProfile model.UserProfile) (model.UserProfile, error) {
	tx := r.getTx(ctx)

	rows, err := tx.Query(ctx,
		"INSERT INTO user_profiles (user_id, birth_date, height_cm, weight_kg, arm_span_cm, dominant_hand, climbing_level, grading_system, years_of_practice, bio, avatar_object_key) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11) RETURNING *",
		userProfile.UserID,
		userProfile.BirthDate,
		userProfile.HeightCM,
		userProfile.WeightKG,
		userProfile.ArmSpanCM,
		userProfile.DominantHand,
		userProfile.ClimbingLevel,
		userProfile.GradingSystem,
		userProfile.YearsOfPratice,
		userProfile.Bio,
		userProfile.AvatarObjectKey,
	)
	if err != nil {
		return model.UserProfile{}, dto.Error(err)
	}

	dbProfile, err := pgx.CollectExactlyOneRow(rows, pgx.RowToStructByName[dto.UserProfile])
	if err != nil {
		return model.UserProfile{}, dto.Error(err)
	}

	return dbProfile.ToUserProfile(), nil
}

func userProfileFilterQuery(filter model.UserProfileFilter) (string, []any) {
	setParts := []string{}
	args := []any{}

	setArg(&setParts, &args, "user_id", filter.UserID)
	setArg(&setParts, &args, "birth_date", filter.BirthDate)
	setArg(&setParts, &args, "height_cm", filter.HeightCM)
	setArg(&setParts, &args, "weight_kg", filter.WeightKG)
	setArg(&setParts, &args, "arm_span_cm", filter.ArmSpanCM)
	setArg(&setParts, &args, "dominant_hand", filter.DominantHand)
	setArg(&setParts, &args, "climbing_level", filter.ClimbingLevel)
	setArg(&setParts, &args, "grading_system", filter.GradingSystem)
	setArg(&setParts, &args, "years_of_practice", filter.YearsOfPratice)
	setArg(&setParts, &args, "bio", filter.Bio)
	setArg(&setParts, &args, "avatar_object_key", filter.AvatarObjectKey)

	query := "SELECT * FROM user_profiles"
	if len(setParts) > 0 {
		query += " WHERE " + strings.Join(setParts, " AND ")
	}

	return query, args
}

func (r *PostgresRepository) GetUserProfileByFilter(ctx context.Context, filter model.UserProfileFilter) (model.UserProfile, error) {
	query, args := userProfileFilterQuery(filter)
	query += " LIMIT 1"

	tx := r.getTx(ctx)

	rows, err := tx.Query(ctx, query, args...)
	if err != nil {
		return model.UserProfile{}, dto.Error(err)
	}

	dbProfile, err := pgx.CollectExactlyOneRow(rows, pgx.RowToStructByName[dto.UserProfile])
	if err != nil {
		return model.UserProfile{}, dto.Error(err)
	}

	return dbProfile.ToUserProfile(), nil
}

func (r *PostgresRepository) UpdateUserProfile(ctx context.Context, partial model.UserProfilePartial) (model.UserProfile, error) {
	setParts := []string{}
	args := []any{}

	setArg(&setParts, &args, "birth_date", partial.BirthDate)
	setArg(&setParts, &args, "height_cm", partial.HeightCM)
	setArg(&setParts, &args, "weight_kg", partial.WeightKG)
	setArg(&setParts, &args, "arm_span_cm", partial.ArmSpanCM)
	setArg(&setParts, &args, "dominant_hand", partial.DominantHand)
	setArg(&setParts, &args, "climbing_level", partial.ClimbingLevel)
	setArg(&setParts, &args, "grading_system", partial.GradingSystem)
	setArg(&setParts, &args, "years_of_practice", partial.YearsOfPratice)
	setArg(&setParts, &args, "bio", partial.Bio)
	setArg(&setParts, &args, "avatar_object_key", partial.AvatarObjectKey)

	if len(setParts) == 0 {
		return model.UserProfile{}, model.ErrNotFound
	}

	args = append(args, partial.UserID)

	tx := r.getTx(ctx)

	query := fmt.Sprintf(
		"UPDATE user_profiles SET %s WHERE user_id = $%d RETURNING *",
		strings.Join(setParts, ", "),
		len(args),
	)

	rows, err := tx.Query(ctx, query, args...)
	if err != nil {
		return model.UserProfile{}, dto.Error(err)
	}

	dbProfile, err := pgx.CollectExactlyOneRow(rows, pgx.RowToStructByName[dto.UserProfile])
	if err != nil {
		return model.UserProfile{}, dto.Error(err)
	}

	return dbProfile.ToUserProfile(), nil
}

func (r *PostgresRepository) DeleteUserProfile(ctx context.Context, userID uuid.UUID) error {
	tx := r.getTx(ctx)

	_, err := tx.Exec(ctx,
		"DELETE FROM user_profiles WHERE user_id = $1",
		userID)
	if err != nil {
		return dto.Error(err)
	}

	return nil
}
