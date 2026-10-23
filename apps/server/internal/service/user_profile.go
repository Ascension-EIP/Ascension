package service

import (
	"context"
	"fmt"
	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
)

type UserProfileService struct {
	repo model.UserRepository
}

func NewUserProfileService(repo model.UserRepository) UserProfileService {
	return UserProfileService{repo: repo}
}

func (s *UserProfileService) CreateUserProfile(ctx context.Context, userProfile model.UserProfile) (model.UserProfile, error) {
	if err := userProfile.Validate(); err != nil {
		return model.UserProfile{}, fmt.Errorf("user profile validation: %w", err)
	}

	userProfile, err := s.repo.CreateUserProfile(ctx, userProfile)
	if err != nil {
		return model.UserProfile{}, fmt.Errorf("create user profile in repo: %w", err)
	}

	return userProfile, nil
}

func (s *UserProfileService) GetUserProfileByUserID(ctx context.Context, userID uuid.UUID) (model.UserProfile, error) {
	userProfile, err := s.repo.GetUserProfileByFilter(ctx, model.UserProfileFilter{UserID: &userID})
	if err != nil {
		return model.UserProfile{}, fmt.Errorf("get user profile by filter in repo: %w", err)
	}

	return userProfile, nil
}

func (s *UserProfileService) UpdateUserProfile(ctx context.Context, partial model.UserProfilePartial) (model.UserProfile, error) {
	userProfile, err := s.repo.UpdateUserProfile(ctx, partial)
	if err != nil {
		return model.UserProfile{}, fmt.Errorf("update user profile in repo: %w", err)
	}

	return userProfile, nil
}

func (s *UserProfileService) DeleteUserProfile(ctx context.Context, userID uuid.UUID) error {
	err := s.repo.DeleteUserProfile(ctx, userID)
	if err != nil {
		return fmt.Errorf("delete user profile in repo: %w", err)
	}

	return nil
}
