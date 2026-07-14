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
