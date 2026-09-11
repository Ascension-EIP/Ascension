// @date 2026-03-11
// @file user.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package service

import (
	"context"
	"fmt"

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"golang.org/x/crypto/bcrypt"
)

type UserService struct {
	repo model.UserRepository
}

func NewUserService(repo model.UserRepository) UserService {
	return UserService{repo: repo}
}

func (s *UserService) CreateUser(ctx context.Context, user model.User) (model.User, error) {
	if err := user.IsValid(); err != nil {
		return model.User{}, fmt.Errorf("user validation: %w", err)
	}

	hashPassword, err := bcrypt.GenerateFromPassword(user.Password, bcrypt.DefaultCost)
	if err != nil {
		return model.User{}, fmt.Errorf("create password hash for new user %v: %w", user.Email, err)
	}
	user.Password = hashPassword

	return s.repo.CreateUser(ctx, user)
}

func (s *UserService) GetUserByID(ctx context.Context, userID uuid.UUID) (model.User, error) {
	user, err := s.repo.GetUserByFilter(ctx, model.UserFilter{ID: &userID})
	if err != nil {
		return model.User{}, fmt.Errorf("get user with id %v: %w", userID, err)
	}

	return user, nil
}

func (s *UserService) GetUserByFilter(ctx context.Context, filter model.UserFilter) (model.User, error) {
	user, err := s.repo.GetUserByFilter(ctx, filter)
	if err != nil {
		return model.User{}, fmt.Errorf("get user for filter %v: %w", filter, err)
	}

	return user, nil
}

func (s *UserService) ListAllUsers(ctx context.Context) ([]model.User, error) {
	users, err := s.repo.ListUsersByFilter(ctx, model.UserFilter{})
	if err != nil {
		return []model.User{}, fmt.Errorf("list all users: %w", err)
	}

	return users, nil
}

func (s *UserService) ListUsersByFilter(ctx context.Context, filter model.UserFilter) ([]model.User, error) {
	users, err := s.repo.ListUsersByFilter(ctx, filter)
	if err != nil {
		return []model.User{}, fmt.Errorf("list users for filter %v: %w", filter, err)
	}

	return users, nil
}

func (s *UserService) UpdateUser(ctx context.Context, partial model.UserPartial) (model.User, error) {
	if err := partial.IsValid(); err != nil {
		return model.User{}, fmt.Errorf("user validation: %w", err)
	}

	user, err := s.repo.UpdateUser(ctx, partial)
	if err != nil {
		return model.User{}, fmt.Errorf("update user %s: %w", partial.ID.String(), err)
	}

	return user, nil
}

func (s *UserService) DeleteUser(ctx context.Context, id uuid.UUID) error {
	if err := s.repo.DeleteUser(ctx, id); err != nil {
		return fmt.Errorf("delete user %s: %w", id.String(), err)
	}

	return nil
}
