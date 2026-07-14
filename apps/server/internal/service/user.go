package service

import (
	"context"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

type userRepository interface {
	CreateUser(context.Context, *model.NewUser) (*model.User, error)
	GetUserByID(context.Context, uuid.UUID) (*model.User, error)
	ListAllUsers(context.Context) ([]*model.User, error)
	UpdateUser(context.Context, *model.PartialUser) (*model.User, error)
	DeleteUser(context.Context, uuid.UUID) error
}

type UserService struct {
	r userRepository
}

func NewUserService(r userRepository) UserService {
	return UserService{r: r}
}

func (s *UserService) CreateUser(c context.Context, user *model.NewUser) (*model.User, error) {
	hashPassword, err := bcrypt.GenerateFromPassword(user.Password, bcrypt.DefaultCost)
	if err != nil {
		return nil, err
	}
	user.Password = hashPassword

	return s.r.CreateUser(c, user)
}

func (s *UserService) GetUserByID(c context.Context, id uuid.UUID) (*model.User, error) {
	return s.r.GetUserByID(c, id)
}

func (s *UserService) ListAllUsers(c context.Context) ([]*model.User, error) {
	return s.r.ListAllUsers(c)
}

func (s *UserService) UpdateUser(c context.Context, user *model.PartialUser) (*model.User, error) {
	return s.r.UpdateUser(c, user)
}

func (s *UserService) DeleteUser(c context.Context, id uuid.UUID) error {
	return s.r.DeleteUser(c, id)
}
