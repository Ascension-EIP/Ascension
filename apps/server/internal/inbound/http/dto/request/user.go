package request

import (
	"errors"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/google/uuid"
)

type CreateUser struct {
	Name     string         `json:"name" binding:"required"`
	Email    string         `json:"email" binding:"required,email"`
	Password string         `json:"password" binding:"required"`
	Role     model.UserRole `json:"role" binding:"required"`
}

func (req *CreateUser) IntoNewUser() (model.NewUser, error) {
	return model.NewUser{
		Name:     req.Name,
		Email:    req.Email,
		Password: []byte(req.Password),
		Role:     req.Role,
	}, nil
}

type UpdateUser struct {
	Name     *string         `json:"name,omitempty"`
	Email    *string         `json:"email,omitempty" binding:"omitempty,email"`
	Password *string         `json:"password,omitempty"`
	Role     *model.UserRole `json:"role,omitempty"`
}

func (req *UpdateUser) IntoPartialUser(idStr string) (model.PartialUser, error) {
	id, err := IntoUserID(idStr)
	if err != nil {
		return model.PartialUser{}, err
	}

	var bytePassword []byte
	if req.Password != nil {
		bytePassword = []byte(*(req.Password))
	}

	return model.PartialUser{
		ID:       id,
		Name:     req.Name,
		Email:    req.Email,
		Password: &bytePassword,
		Role:     req.Role,
	}, nil
}

func IntoUserID(s string) (uuid.UUID, error) {
	id, err := uuid.Parse(s)
	if err != nil {
		return uuid.UUID{}, errors.New("invalid user id")
	}
	return id, nil
}
