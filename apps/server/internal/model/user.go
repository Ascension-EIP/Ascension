// @date 2026-09-17
// @file user.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>, Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package model

import (
	"fmt"
	"strings"
	"time"
	"uuid"

	"golang.org/x/crypto/bcrypt"
)

type UserUsername string

func (n UserUsername) Validate() error {
	if len(n) < 6 {
		return fmt.Errorf("too short")
	}
	if len(n) > 24 {
		return fmt.Errorf("too long")
	}
	return nil
}

type UserEmail string

// NewUserEmail normalizes an email so the same address always maps to a single account.
func NewUserEmail(email string) UserEmail {
	return UserEmail(strings.ToLower(strings.TrimSpace(email)))
}

func (e UserEmail) Validate() error {
	return nil
}

type UserPassword []byte

func (p UserPassword) Validate() error {
	if len(p) < 8 {
		return fmt.Errorf("too short")
	}
	if len(p) > 64 {
		return fmt.Errorf("too long")
	}
	return nil
}

func (p UserPassword) Hash() ([]byte, error) {
	hashed, err := bcrypt.GenerateFromPassword(p, bcrypt.DefaultCost)
	if err != nil {
		return []byte{}, err
	}

	return hashed, nil
}

type UserRole string

const (
	UserRoleAdmin UserRole = "admin"
	UserRoleUser  UserRole = "user"
	UserRoleCoach UserRole = "coach"
	UserRoleGym   UserRole = "gym"
)

func (r UserRole) Validate() error {
	switch r {
	case UserRoleAdmin, UserRoleUser, UserRoleCoach, UserRoleGym:
		return nil
	default:
		return fmt.Errorf("unknown")
	}
}

type UserStatus string

const (
	UserStatusActive      UserStatus = "active"
	UserStatusDeactivated UserStatus = "deactivated"
)

func (r UserStatus) Validate() error {
	switch r {
	case UserStatusActive, UserStatusDeactivated:
		return nil
	default:
		return fmt.Errorf("unknown")
	}
}

type UserFilter struct {
	ID               *uuid.UUID
	Username         *UserUsername
	FirstName        *string
	LastName         *string
	Email            *UserEmail
	Password         *UserPassword
	Role             *UserRole
	Status           *UserStatus
	StripeCustomerID **string
	EmailVerifiedAt  **time.Time
	LastLoginAt      **time.Time
	DeactivatedAt    **time.Time
}

type UserPartial struct {
	ID               uuid.UUID
	Username         *UserUsername
	FirstName        *string
	LastName         *string
	Email            *UserEmail
	Password         *UserPassword
	Role             *UserRole
	Status           *UserStatus
	StripeCustomerID **string
	EmailVerifiedAt  **time.Time
	LastLoginAt      **time.Time
	DeactivatedAt    **time.Time
}

func (u UserPartial) Validate() error {
	if err := u.Username.Validate(); err != nil {
		return fmt.Errorf("username: %w", err)
	}

	if err := u.Email.Validate(); err != nil {
		return fmt.Errorf("email: %w", err)
	}

	if err := u.Password.Validate(); err != nil {
		return fmt.Errorf("password: %w", err)
	}

	if err := u.Role.Validate(); err != nil {
		return fmt.Errorf("role: %w", err)
	}

	if err := u.Status.Validate(); err != nil {
		return fmt.Errorf("status: %w", err)
	}

	return nil
}

type User struct {
	ID               uuid.UUID
	Username         UserUsername
	FirstName        string
	LastName         string
	Email            UserEmail
	Password         UserPassword
	Role             UserRole
	Status           UserStatus
	StripeCustomerID *string
	EmailVerifiedAt  *time.Time
	LastLoginAt      *time.Time
	DeactivatedAt    *time.Time
	CreatedAt        time.Time
	UpdatedAt        time.Time
}

func (u User) Validate() error {
	if err := u.Username.Validate(); err != nil {
		return fmt.Errorf("username: %w", err)
	}

	if err := u.Email.Validate(); err != nil {
		return fmt.Errorf("email: %w", err)
	}

	if err := u.Password.Validate(); err != nil {
		return fmt.Errorf("password: %w", err)
	}

	if err := u.Role.Validate(); err != nil {
		return fmt.Errorf("role: %w", err)
	}

	if err := u.Status.Validate(); err != nil {
		return fmt.Errorf("status: %w", err)
	}

	return nil
}
