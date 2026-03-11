package repo

import (
	"context"
	"errors"

	"github.com/DimitriLaPoudre/go-backend-base/internal/entity"
	"github.com/DimitriLaPoudre/go-backend-base/internal/repo/model"
	"gorm.io/gorm"
)

func (r *Repo) CreateUser(ctx context.Context, user *entity.User) error {
	if user == nil {
		return ErrModelNil
	}
	m := model.UserFromEntity(user)
	if err := r.db.WithContext(ctx).Create(m).Error; err != nil {
		switch {
		case errors.Is(err, gorm.ErrDuplicatedKey):
			return ErrDuplicatedKey
		default:
			return err
		}
	}
	user.ID = m.ID
	user.CreatedAt = m.CreatedAt
	user.UpdatedAt = m.UpdatedAt
	return nil
}

func (r *Repo) GetUserByID(ctx context.Context, id uint) (*entity.User, error) {
	var user model.User
	if err := r.db.WithContext(ctx).First(&user, id).Error; err != nil {
		switch {
		case errors.Is(err, gorm.ErrRecordNotFound):
			return nil, ErrNotFound
		default:
			return nil, err
		}
	}
	return model.UserToEntity(&user), nil
}

func (r *Repo) GetUserByUsername(ctx context.Context, username string) (*entity.User, error) {
	var user model.User
	if err := r.db.WithContext(ctx).First(&user, "username = ?", username).Error; err != nil {
		switch {
		case errors.Is(err, gorm.ErrRecordNotFound):
			return nil, ErrNotFound
		default:
			return nil, err
		}
	}
	return model.UserToEntity(&user), nil
}

func (r *Repo) ListAllUsers(ctx context.Context) ([]entity.User, error) {
	var users []model.User
	if err := r.db.WithContext(ctx).Find(&users).Error; err != nil {
		return nil, err
	}
	return model.UsersToEntity(users), nil
}

func (r *Repo) UpdateUser(ctx context.Context, user *entity.User) error {
	if user == nil {
		return ErrModelNil
	}
	m := model.UserFromEntity(user)
	if err := r.db.WithContext(ctx).Updates(m).Error; err != nil {
		return err
	}
	return nil
}

func (r *Repo) DeleteUser(ctx context.Context, id uint) error {
	if err := r.db.WithContext(ctx).Where("id = ?", id).Delete(&model.User{}).Error; err != nil {
		return err
	}
	return nil
}
