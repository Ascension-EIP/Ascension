package dto

import (
	"time"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/google/uuid"
)

type User struct {
	ID        uuid.UUID      `db:"id"`
	Name      string         `db:"name"`
	Email     string         `db:"email"`
	Password  []byte         `db:"password"`
	Role      model.UserRole `db:"role"`
	CreatedAt time.Time      `db:"created_at"`
	UpdatedAt time.Time      `db:"updated_at"`
}

func (u *User) ToUser() *model.User {
	return &model.User{
		ID:       u.ID,
		Name:     u.Name,
		Email:    u.Email,
		Password: u.Password,
		Role:     u.Role,
	}
}

func UsersToUsers(dto []*User) []*model.User {
	users := []*model.User{}
	for _, user := range dto {
		users = append(users, &model.User{
			ID:       user.ID,
			Name:     user.Name,
			Email:    user.Email,
			Password: user.Password,
			Role:     user.Role,
		})
	}
	return users
}
