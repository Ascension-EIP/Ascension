package user

import (
	"context"

	"github.com/DimitriLaPoudre/go-backend-base/internal/entity"
	"github.com/DimitriLaPoudre/go-backend-base/internal/infra/config"
)

type repository interface {
	CreateUser(ctx context.Context, user *entity.User) error
	GetUserByID(ctx context.Context, id uint) (*entity.User, error)
	ListAllUsers(ctx context.Context) ([]entity.User, error)
	UpdateUser(ctx context.Context, user *entity.User) error
	DeleteUser(ctx context.Context, id uint) error
}

type Service struct {
	r repository
}

func New(cfg *config.Config, r repository) *Service {
	return &Service{r: r}
}

func (s *Service) CreateUser(c context.Context, user *entity.User) error {
	return s.r.CreateUser(c, user)
}

func (s *Service) GetUserByID(c context.Context, id uint) (*entity.User, error) {
	return s.r.GetUserByID(c, id)
}

func (s *Service) IsAdmin(c context.Context, id uint) error {
	user, err := s.r.GetUserByID(c, id)
	if err != nil {
		return err
	}
	if user.Type != entity.UserTypeAdmin {
		return entity.ErrForbidden
	}
	return nil
}

func (s *Service) IsUser(c context.Context, id uint) error {
	user, err := s.r.GetUserByID(c, id)
	if err != nil {
		return err
	}
	if user.Type != entity.UserTypeUser {
		return entity.ErrForbidden
	}
	return nil
}

func (s *Service) ListAllUsers(c context.Context) ([]entity.User, error) {
	return s.r.ListAllUsers(c)
}

func (s *Service) UpdateUser(c context.Context, user *entity.User) error {
	return s.r.UpdateUser(c, user)
}

func (s *Service) DeleteUser(c context.Context, id uint) error {
	return s.r.DeleteUser(c, id)
}
