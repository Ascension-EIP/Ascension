// @date 2026-03-11
// @file user.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package dto

import (
	"time"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/google/uuid"
)

type User struct {
	ID               uuid.UUID      `db:"id"`
	Email            string         `db:"email"`
	Username         string         `db:"username"`
	FirstName        string         `db:"first_name"`
	LastName         string         `db:"last_name"`
	PasswordHash     []byte         `db:"password_hash"`
	Role             model.UserRole `db:"role"`
	Status           string         `db:"status"`
	EmailVerifiedAt  *time.Time     `db:"email_verified_at"`
	LastLoginAt      *time.Time     `db:"last_login_at"`
	DeactivatedAt    *time.Time     `db:"deactivated_at"`
	StripeCustomerID *string        `db:"stripe_customer_id"`
	CreatedAt        time.Time      `db:"created_at"`
	UpdatedAt        time.Time      `db:"updated_at"`
}

func (u *User) ToUser() *model.User {
	return &model.User{
		ID:              u.ID,
		Username:        u.Username,
		FirstName:       u.FirstName,
		LastName:        u.LastName,
		Email:           u.Email,
		Password:        u.PasswordHash,
		Role:            u.Role,
		Status:          model.UserStatus(u.Status),
		EmailVerifiedAt: u.EmailVerifiedAt,
		LastLoginAt:     u.LastLoginAt,
		DeactivatedAt:   u.DeactivatedAt,
		CreatedAt:       u.CreatedAt,
		UpdatedAt:       u.UpdatedAt,
	}
}

func UsersToUsers(dto []*User) []*model.User {
	users := make([]*model.User, 0, len(dto))
	for _, user := range dto {
		users = append(users, user.ToUser())
	}
	return users
}
