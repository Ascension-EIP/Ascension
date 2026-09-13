// @date 2026-03-19
// @file auth.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package model

type SignupForm struct {
	Name     UserName
	Email    UserEmail
	Password UserPassword
}

type LoginForm struct {
	Email    UserEmail
	Password UserPassword
}

type Tokens struct {
	RefreshToken
	AccessToken
}

type RefreshToken struct {
	SessionToken string
}

type AccessToken struct {
	Token     string
	TokenType string
	ExpiresIn uint
}
