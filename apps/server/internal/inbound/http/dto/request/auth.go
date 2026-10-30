// @date 2026-10-30
// @file auth.go
// @brief File description.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>, DimitriLaPoudre <lou.pellegrino@epitech.eu>, Gianni TUERO <gianni.tuero@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package request

import (
	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
)

type RegisterForm struct {
	Username  string `json:"username" binding:"required"`
	FirstName string `json:"first_name" binding:"required"`
	LastName  string `json:"last_name" binding:"required"`
	Email     string `json:"email" binding:"required,email"`
	Password  string `json:"password" binding:"required"`
	Remember  bool   `json:"remember"`
}

func (req *RegisterForm) IntoRegisterForm() (model.RegisterForm, error) {
	return model.RegisterForm{
		Username:  model.UserUsername(req.Username),
		FirstName: req.FirstName,
		LastName:  req.LastName,
		Email:     model.NewUserEmail(req.Email),
		Password:  model.UserPassword(req.Password),
	}, nil
}

type LoginForm struct {
	Identifier string `json:"identifier" binding:"required"`
	Password   string `json:"password" binding:"required"`
	Remember   bool   `json:"remember"`
}

func (req *LoginForm) IntoLoginForm() (model.LoginForm, error) {
	return model.LoginForm{
		Identifier: req.Identifier,
		Password:   model.UserPassword(req.Password),
	}, nil
}

type RefreshToken struct {
	Token string `json:"refresh_token" binding:"required"`
}
