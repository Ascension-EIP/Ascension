// @date 2026-03-11
// @file user.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package model

import "github.com/google/uuid"

type NewUser struct {
	Name     string
	Email    string
	Password []byte
	Role     UserRole
}

type PartialUser struct {
	ID       uuid.UUID
	Name     *string
	Email    *string
	Password *[]byte
	Role     *UserRole
}

type UserClear struct {
	ID       uuid.UUID
	Name     string
	Email    string
	Password []byte
	Role     UserRole
}

type User struct {
	ID       uuid.UUID
	Name     string
	Email    string
	Password []byte
	Role     UserRole
}
