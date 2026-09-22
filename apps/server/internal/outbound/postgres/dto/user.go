// @date 2026-09-20
// @file user.go
// @brief File description.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>, DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package dto

import (
	"time"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"uuid"
)

type User struct {
	ID               uuid.UUID          `db:"id"`
	Username         model.UserUsername `db:"username"`
	FirstName        string             `db:"first_name"`
	LastName         string             `db:"last_name"`
	Email            model.UserEmail    `db:"email"`
	Password         model.UserPassword `db:"password_hash"`
	Role             model.UserRole     `db:"role"`
	Status           model.UserStatus   `db:"status"`
	StripeCustomerID *string            `db:"stripe_customer_id"`
	EmailVerifiedAt  *time.Time         `db:"email_verified_at"`
	LastLoginAt      *time.Time         `db:"last_login_at"`
	DeactivatedAt    *time.Time         `db:"deactivated_at"`
	CreatedAt        time.Time          `db:"created_at"`
	UpdatedAt        time.Time          `db:"updated_at"`
}

func (u User) ToUser() model.User {
	return model.User{
		ID:               u.ID,
		Username:         u.Username,
		FirstName:        u.FirstName,
		LastName:         u.LastName,
		Email:            u.Email,
		Password:         u.Password,
		Role:             u.Role,
		Status:           u.Status,
		StripeCustomerID: u.StripeCustomerID,
		EmailVerifiedAt:  u.EmailVerifiedAt,
		LastLoginAt:      u.LastLoginAt,
		DeactivatedAt:    u.DeactivatedAt,
		CreatedAt:        u.CreatedAt,
		UpdatedAt:        u.UpdatedAt,
	}
}

func UsersToUsers(dto []User) []model.User {
	users := make([]model.User, 0, len(dto))
	for _, user := range dto {
		users = append(users, user.ToUser())
	}

	return users
}
