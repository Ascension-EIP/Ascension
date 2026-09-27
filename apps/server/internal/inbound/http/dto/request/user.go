// @date 2026-09-20
// @file user.go
// @brief File description.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>, DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package request

import (
	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"uuid"
)

type CreateUser struct {
	Username  model.UserUsername `json:"username" binding:"required"`
	FirstName string             `json:"first_name" binding:"required"`
	LastName  string             `json:"last_name" binding:"required"`
	Email     string             `json:"email" binding:"required"`
	Password  string             `json:"password" binding:"required"`
	Role      string             `json:"role" binding:"required"`
}

func (req *CreateUser) IntoUser() (model.User, error) {
	return model.User{
		Username:  model.UserUsername(req.Username),
		FirstName: req.FirstName,
		LastName:  req.LastName,
		Email:     model.NewUserEmail(req.Email),
		Password:  model.UserPassword(req.Password),
		Role:      model.UserRole(req.Role),
		Status:    model.UserStatusActive,
	}, nil
}

type UpdateUser struct {
	Username  *string `json:"username"`
	FirstName *string `json:"first_name"`
	LastName  *string `json:"last_name"`
	Email     *string `json:"email"`
	Password  *string `json:"password"`
	Role      *string `json:"role"`
	Status    *string `json:"status"`
}

func (req *UpdateUser) IntoUserPartial(id string) (model.UserPartial, error) {
	userID, err := uuid.Parse(id)
	if err != nil {
		return model.UserPartial{}, err
	}

	userPartial := model.UserPartial{
		ID: userID,
	}

	if req.Username != nil {
		username := model.UserUsername(*req.Username)
		userPartial.Username = &username
	}

	if req.FirstName != nil {
		firstName := *req.FirstName
		userPartial.FirstName = &firstName
	}

	if req.LastName != nil {
		lastName := *req.LastName
		userPartial.LastName = &lastName
	}

	if req.Email != nil {
		email := model.NewUserEmail(*req.Email)
		userPartial.Email = &email
	}

	if req.Password != nil {
		password := model.UserPassword(*req.Password)
		userPartial.Password = &password
	}

	if req.Role != nil {
		role := model.UserRole(*req.Role)
		userPartial.Role = &role
	}

	if req.Status != nil {
		status := model.UserStatus(*req.Status)
		userPartial.Status = &status
	}

	return userPartial, nil
}
