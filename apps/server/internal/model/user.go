// @date 2026-09-18
// @file user.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>, Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package model

import (
	"time"

	"github.com/google/uuid"
)

type UserStatus string

const (
	UserStatusActive      UserStatus = "active"
	UserStatusDeactivated UserStatus = "deactivated"
)

type NewUser struct {
	Username  string
	FirstName string
	LastName  string
	Email     string
	Password  []byte
	Role      UserRole
}

type PartialUser struct {
	ID        uuid.UUID
	Username  *string
	FirstName *string
	LastName  *string
	Email     *string
	Password  *[]byte
	Role      *UserRole
}

type UserClear struct {
	ID        uuid.UUID
	Username  string
	FirstName string
	LastName  string
	Email     string
	Password  []byte
	Role      UserRole
}

type User struct {
	ID              uuid.UUID
	Username        string
	FirstName       string
	LastName        string
	Email           string
	Password        []byte
	Role            UserRole
	Status          UserStatus
	EmailVerifiedAt *time.Time
	LastLoginAt     *time.Time
	DeactivatedAt   *time.Time
	CreatedAt       time.Time
	UpdatedAt       time.Time
}
