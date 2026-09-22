// @date 2026-09-20
// @file auth.go
// @brief File description.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>, DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package model

import "net/netip"

type SignupForm struct {
	Username  UserUsername
	FirstName string
	LastName  string
	Email     UserEmail
	Password  UserPassword
}

func (f SignupForm) Validate() error {
	if err := f.Username.Validate(); err != nil {
		return err
	}

	if err := f.Email.Validate(); err != nil {
		return err
	}

	if err := f.Password.Validate(); err != nil {
		return err
	}

	return nil
}

type LoginForm struct {
	Identifier string
	Password   UserPassword
}

func (f LoginForm) Validate() error {
	if err := NewUserEmail(f.Identifier).Validate(); err != nil {
		return err
	}

	if err := f.Password.Validate(); err != nil {
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

type ClientInfo struct {
	UserAgent *string
	IPAddress *netip.Addr
}
