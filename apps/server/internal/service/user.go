package service

import (
	"context"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/google/uuid"
	"github.com/rs/zerolog"
	"golang.org/x/crypto/bcrypt"
)

type userRepository interface {
	CreateUser(ctx context.Context, user *model.NewUser) (*model.User, error)
	GetUserByID(ctx context.Context, id uuid.UUID) (*model.User, error)
	ListAllUsers(ctx context.Context) ([]*model.User, error)
	UpdateUser(ctx context.Context, user *model.PartialUser) (*model.User, error)
	DeleteUser(ctx context.Context, id uuid.UUID) error
}

type UserService struct {
	r userRepository
	l *zerolog.Logger
}

func NewUserService(l *zerolog.Logger, r userRepository) *UserService {
	return &UserService{r: r}
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
