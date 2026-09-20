// @date 2026-03-19
// @file auth.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package model

type SignupForm struct {
	Username  UserUsername
	FirstName string
	LastName  string
	Email     UserEmail
	Password  UserPassword
}

func (f SignupForm) IsValid() error {
	if err := f.Username.IsValid(); err != nil {
		return err
	}

	if err := f.Email.IsValid(); err != nil {
		return err
	}

	if err := f.Password.IsValid(); err != nil {
		return err
	}

	return nil
}

type LoginForm struct {
	Identifier string
	Password   UserPassword
}

func (f LoginForm) IsValid() error {
	if err := NewUserEmail(f.Identifier).IsValid(); err != nil {
		return err
	}

	if err := f.Password.IsValid(); err != nil {
		return err
	}

	return nil
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
