// @date 2026-03-19
// @file auth.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package request

import "github.com/Ascension-EIP/Ascension/apps/server/internal/model"

type SignupForm struct {
	Username  string `json:"username" binding:"required"`
	FirstName string `json:"first_name" binding:"required,max=100"`
	LastName  string `json:"last_name" binding:"required,max=100"`
	Email     string `json:"email" binding:"required,email"`
	Password  string `json:"password" binding:"required,min=8"`
}

func (req *SignupForm) IntoSignupForm() (model.SignupForm, error) {
	if err := model.ValidateUsername(req.Username); err != nil {
		return model.SignupForm{}, err
	}
	return model.SignupForm{
		Username:  req.Username,
		FirstName: req.FirstName,
		LastName:  req.LastName,
		Email:     req.Email,
		Password:  []byte(req.Password),
	}, nil
}

type SignupLoginForm struct {
	Username  string `json:"username" binding:"required"`
	FirstName string `json:"first_name" binding:"required,max=100"`
	LastName  string `json:"last_name" binding:"required,max=100"`
	Email     string `json:"email" binding:"required,email"`
	Password  string `json:"password" binding:"required,min=8"`
	Remember  bool   `json:"remember"`
}

func (req *SignupLoginForm) IntoSignupLoginForm() (model.SignupLoginForm, error) {
	if err := model.ValidateUsername(req.Username); err != nil {
		return model.SignupLoginForm{}, err
	}
	return model.SignupLoginForm{
		Username:  req.Username,
		FirstName: req.FirstName,
		LastName:  req.LastName,
		Email:     req.Email,
		Password:  []byte(req.Password),
		Remember:  req.Remember,
	}, nil
}

type LoginForm struct {
	Email    string `json:"email" binding:"omitempty,email"`
	Password string `json:"password" binding:"required,min=8"`
	Remember bool   `json:"remember"`
}

func (req *LoginForm) IntoLoginForm() (model.LoginForm, error) {
	return model.LoginForm{
		Email:    req.Email,
		Password: []byte(req.Password),
	}, nil
}

type RefreshToken struct {
	Token string `json:"refresh_token" binding:"required"`
}
