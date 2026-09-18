// @date 2026-03-18
// @file user.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package request

import (
	"errors"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/google/uuid"
)

type CreateUser struct {
	Username  string         `json:"username" binding:"required"`
	FirstName string         `json:"first_name" binding:"required,max=100"`
	LastName  string         `json:"last_name" binding:"required,max=100"`
	Email     string         `json:"email" binding:"required,email"`
	Password  string         `json:"password" binding:"required"`
	Role      model.UserRole `json:"role" binding:"required"`
}

func (req *CreateUser) IntoNewUser() (model.NewUser, error) {
	if err := model.ValidateUsername(req.Username); err != nil {
		return model.NewUser{}, err
	}
	return model.NewUser{
		Username:  req.Username,
		FirstName: req.FirstName,
		LastName:  req.LastName,
		Email:     req.Email,
		Password:  []byte(req.Password),
		Role:      req.Role,
	}, nil
}

type UpdateUser struct {
	Username  *string         `json:"username"`
	FirstName *string         `json:"first_name" binding:"omitempty,max=100"`
	LastName  *string         `json:"last_name" binding:"omitempty,max=100"`
	Email     *string         `json:"email" binding:"omitempty,email"`
	Password  *string         `json:"password"`
	Role      *model.UserRole `json:"role"`
}

func (req *UpdateUser) IntoPartialUser(idStr string) (model.PartialUser, error) {
	id, err := IntoUUID(idStr)
	if err != nil {
		return model.PartialUser{}, err
	}

	if req.Username != nil {
		if err := model.ValidateUsername(*req.Username); err != nil {
			return model.PartialUser{}, err
		}
	}

	var bytePassword []byte
	if req.Password != nil {
		bytePassword = []byte(*(req.Password))
	}

	return model.PartialUser{
		ID:        id,
		Username:  req.Username,
		FirstName: req.FirstName,
		LastName:  req.LastName,
		Email:     req.Email,
		Password:  &bytePassword,
		Role:      req.Role,
	}, nil
}

func IntoUUID(s string) (uuid.UUID, error) {
	id, err := uuid.Parse(s)
	if err != nil {
		return uuid.UUID{}, errors.New("invalid uuid")
	}
	return id, nil
}
