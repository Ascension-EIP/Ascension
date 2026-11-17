// @date 2026-11-13
// @file auth_test.go
// @brief Unit tests of the register and login form validation.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package model

import "testing"

func TestRegisterFormValidate(t *testing.T) {
	valid := RegisterForm{
		Username:  "climber",
		FirstName: "Alex",
		LastName:  "Honnold",
		Email:     "climber@ascension.app",
		Password:  UserPassword("password123"),
	}

	tests := []struct {
		name    string
		edit    func(*RegisterForm)
		wantErr bool
	}{
		{name: "valid", edit: func(*RegisterForm) {}},
		{name: "no names", edit: func(f *RegisterForm) { f.FirstName, f.LastName = "", "" }},
		{name: "username too short", edit: func(f *RegisterForm) { f.Username = "abc" }, wantErr: true},
		{name: "password too short", edit: func(f *RegisterForm) { f.Password = UserPassword("short") }, wantErr: true},
		{name: "missing password", edit: func(f *RegisterForm) { f.Password = nil }, wantErr: true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			form := valid
			tt.edit(&form)
			if err := form.Validate(); (err != nil) != tt.wantErr {
				t.Errorf("Validate() = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}

func TestLoginFormValidate(t *testing.T) {
	tests := []struct {
		name    string
		form    LoginForm
		wantErr bool
	}{
		{name: "email identifier", form: LoginForm{Identifier: "climber@ascension.app", Password: UserPassword("password123")}},
		{name: "username identifier", form: LoginForm{Identifier: "climber", Password: UserPassword("password123")}},
		{name: "password too short", form: LoginForm{Identifier: "climber", Password: UserPassword("short")}, wantErr: true},
		{name: "password too long", form: LoginForm{Identifier: "climber", Password: make(UserPassword, 65)}, wantErr: true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if err := tt.form.Validate(); (err != nil) != tt.wantErr {
				t.Errorf("Validate() = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}
