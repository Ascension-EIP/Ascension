package request

import (
	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/google/uuid"
)

type SignupForm struct {
	Name     string `json:"name" binding:"required,min=3,max=20,alphanumunicode|contains=_"`
	Email    string `json:"email" binding:"omitempty,email"`
	Password string `json:"password" binding:"required,min=8"`
}

func (req *SignupForm) IntoSignupForm() (model.SignupForm, error) {
	return model.SignupForm{
		Name:     req.Name,
		Email:    req.Email,
		Password: []byte(req.Password),
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
	Token uuid.UUID `json:"refresh_token" binding:"required"`
}
