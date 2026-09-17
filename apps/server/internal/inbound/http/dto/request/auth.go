// @date 2026-09-17
// @file auth.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>, Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package request

import (
	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
)

type SignupForm struct {
	Name     string `json:"name" binding:"required,min=3,max=20,alphanumunicode|contains=_"`
	Email    string `json:"email" binding:"omitempty,email"`
	Password string `json:"password" binding:"required,min=8"`
}

func (req *SignupForm) IntoSignupForm() (model.SignupForm, error) {
	return model.SignupForm{
		Name:     model.UserName(req.Name),
		Email:    model.NewUserEmail(req.Email),
		Password: model.UserPassword(req.Password),
	}, nil
}

type SignupLoginForm struct {
	Name     string `json:"name" binding:"required,min=3,max=20,alphanumunicode|contains=_"`
	Email    string `json:"email" binding:"omitempty,email"`
	Password string `json:"password" binding:"required,min=8"`
	Remember bool   `json:"remember"`
}

func (req *SignupLoginForm) IntoSignupLoginForm() (model.SignupForm, error) {
	return model.SignupForm{
		Name:     model.UserName(req.Name),
		Email:    model.NewUserEmail(req.Email),
		Password: model.UserPassword(req.Password),
	}, nil
}

type LoginForm struct {
	Email    string `json:"email" binding:"omitempty,email"`
	Password string `json:"password" binding:"required,min=8"`
	Remember bool   `json:"remember"`
}

func (req *LoginForm) IntoLoginForm() (model.LoginForm, error) {
	return model.LoginForm{
		Email:    model.NewUserEmail(req.Email),
		Password: model.UserPassword(req.Password),
	}, nil
}

type RefreshToken struct {
	Token string `json:"refresh_token" binding:"required"`
}
