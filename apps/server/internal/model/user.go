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

func (n UserUsername) IsValid() error {
	if len(n) < 6 {
		return fmt.Errorf("user name too short")
	}
	if len(n) > 24 {
		return fmt.Errorf("user name too long")
	}
	return nil
}

type UserEmail string

// NewUserEmail normalizes an email so the same address always maps to a single account.
func NewUserEmail(email string) UserEmail {
	return UserEmail(strings.ToLower(strings.TrimSpace(email)))
}

func (e UserEmail) IsValid() error {
	return nil
}

type UserPassword []byte

func (p UserPassword) IsValid() error {
	if len(p) < 8 {
		return fmt.Errorf("user password too short")
	}
	if len(p) > 64 {
		return fmt.Errorf("user password too long")
	}
	return nil
}

func (p UserPassword) Hash() ([]byte, error) {
	hashed, err := bcrypt.GenerateFromPassword(p, bcrypt.DefaultCost)
	if err != nil {
		return []byte{}, fmt.Errorf("hash user password: %w", err)
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

func (r UserRole) IsValid() error {
	switch r {
	case UserRoleAdmin, UserRoleUser, UserRoleCoach, UserRoleGym:
		return nil
	default:
		return fmt.Errorf("invalid role")
	}
}

type UserStatus string

const (
	UserStatusActive      UserStatus = "active"
	UserStatusDeactivated UserStatus = "deactivated"
)

func (r UserStatus) IsValid() error {
	switch r {
	case UserStatusActive, UserStatusDeactivated:
		return nil
	default:
		return fmt.Errorf("invalid status")
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

func (u UserPartial) IsValid() error {
	if err := u.Username.IsValid(); err != nil {
		return err
	}

	if err := u.Email.IsValid(); err != nil {
		return err
	}

	if err := u.Password.IsValid(); err != nil {
		return err
	}

	if err := u.Role.IsValid(); err != nil {
		return err
	}

	if err := u.Status.IsValid(); err != nil {
		return err
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

func (u User) IsValid() error {
	if err := u.Username.IsValid(); err != nil {
		return err
	}

	if err := u.Email.IsValid(); err != nil {
		return err
	}

	if err := u.Password.IsValid(); err != nil {
		return err
	}

	if err := u.Role.IsValid(); err != nil {
		return err
	}

	if err := u.Status.IsValid(); err != nil {
		return err
	}

	return nil
}
