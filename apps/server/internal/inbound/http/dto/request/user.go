// @date 2026-09-17
// @file user.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>, Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package request

import (
	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"uuid"
)

type CreateUser struct {
	Name     model.UserName `json:"name" binding:"required"`
	Email    string         `json:"email" binding:"required"`
	Password string         `json:"password" binding:"required"`
	Role     string         `json:"role" binding:"required"`
}

func (req *CreateUser) IntoUser() (model.User, error) {
	return model.User{
		Name:     model.UserName(req.Name),
		Email:    model.NewUserEmail(req.Email),
		Password: model.UserPassword(req.Password),
		Role:     model.UserRole(req.Role),
	}, nil
}

type UpdateUser struct {
	Name     *string `json:"name"`
	Email    *string `json:"email"`
	Password *string `json:"password"`
	Role     *string `json:"role"`
}

func (req *UpdateUser) IntoUserPartial(id string) (model.UserPartial, error) {
	userID, err := uuid.Parse(id)
	if err != nil {
		return model.UserPartial{}, err
	}

	userPartial := model.UserPartial{
		ID: userID,
	}

	if req.Name != nil {
		userPartial.Name = new(model.UserName(*req.Name))
	}
	if req.Email != nil {
		userPartial.Email = new(model.NewUserEmail(*req.Email))
	}
	if req.Password != nil {
		userPartial.Password = new(model.UserPassword(*req.Password))
	}
	if req.Role != nil {
		userPartial.Role = new(model.UserRole(*req.Role))
	}

	return userPartial, nil
}
