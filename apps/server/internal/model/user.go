// @date 2026-03-11
// @file user.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package model

import (
	"fmt"
	"uuid"
)

type UserName string

func (n UserName) IsValid() error {
	if len(n) < 6 {
		return fmt.Errorf("user name too short")
	}
	if len(n) > 24 {
		return fmt.Errorf("user name too long")
	}
	return nil
}

type UserEmail string

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

type UserRole string

const (
	UserRoleAdmin UserRole = "admin"
	UserRoleUser  UserRole = "user"
)

func (r UserRole) IsValid() error {
	switch r {
	case UserRoleAdmin, UserRoleUser:
		return nil
	default:
		return fmt.Errorf("invalid role")
	}
}

type UserFilter struct {
	ID       *uuid.UUID
	Name     *UserName
	Email    *UserEmail
	Password *UserPassword
	Role     *UserRole
}

type UserPartial struct {
	ID       uuid.UUID
	Name     *UserName
	Email    *UserEmail
	Password *UserPassword
	Role     *UserRole
}

type User struct {
	ID       uuid.UUID
	Name     UserName
	Email    UserEmail
	Password UserPassword
	Role     UserRole
}
