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

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"golang.org/x/crypto/bcrypt"
	"uuid"
)

type UserService struct {
	repo model.UserRepository
}

func NewUserService(repo model.UserRepository) UserService {
	return UserService{repo: repo}
}

func (s *UserService) CreateUser(c context.Context, user *model.NewUser) (*model.User, error) {
	hashPassword, err := bcrypt.GenerateFromPassword(user.Password, bcrypt.DefaultCost)
	if err != nil {
		return nil, err
	}
	user.Password = hashPassword

	return s.repo.CreateUser(c, user)
}

func (s *UserService) GetUserByID(c context.Context, id uuid.UUID) (*model.User, error) {
	return s.repo.GetUserByID(c, id)
}

func (s *UserService) ListAllUsers(c context.Context) ([]*model.User, error) {
	return s.repo.ListAllUsers(c)
}

func (s *UserService) UpdateUser(c context.Context, user *model.PartialUser) (*model.User, error) {
	return s.repo.UpdateUser(c, user)
}

func (s *UserService) DeleteUser(c context.Context, id uuid.UUID) error {
	return s.repo.DeleteUser(c, id)
}
