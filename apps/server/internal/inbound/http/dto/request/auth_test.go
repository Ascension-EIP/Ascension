// @date 2026-11-13
// @file auth_test.go
// @brief Unit tests of the register, login and refresh request DTOs: binding rules and conversion.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package request

import (
	"testing"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/gin-gonic/gin/binding"
)

// bindJSON decodes and validates body like gin's ShouldBindJSON.
func bindJSON(body string, out any) error {
	return binding.JSON.BindBody([]byte(body), out)
}

func TestRegisterFormBinding(t *testing.T) {
	tests := []struct {
		name    string
		body    string
		wantErr bool
	}{
		{name: "complete", body: `{"username":"climber","first_name":"Alex","last_name":"Honnold","email":"climber@ascension.app","password":"password123","remember":true}`},
		{name: "remember is optional", body: `{"username":"climber","first_name":"Alex","last_name":"Honnold","email":"climber@ascension.app","password":"password123"}`},
		{name: "missing username", body: `{"first_name":"Alex","last_name":"Honnold","email":"climber@ascension.app","password":"password123"}`, wantErr: true},
		{name: "missing first name", body: `{"username":"climber","last_name":"Honnold","email":"climber@ascension.app","password":"password123"}`, wantErr: true},
		{name: "missing last name", body: `{"username":"climber","first_name":"Alex","email":"climber@ascension.app","password":"password123"}`, wantErr: true},
		{name: "missing password", body: `{"username":"climber","first_name":"Alex","last_name":"Honnold","email":"climber@ascension.app"}`, wantErr: true},
		{name: "invalid email", body: `{"username":"climber","first_name":"Alex","last_name":"Honnold","email":"not-an-email","password":"password123"}`, wantErr: true},
		{name: "not json", body: `username=climber`, wantErr: true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			var form RegisterForm
			if err := bindJSON(tt.body, &form); (err != nil) != tt.wantErr {
				t.Errorf("bind = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}

func TestRegisterFormIntoRegisterForm(t *testing.T) {
	req := RegisterForm{
		Username:  "climber",
		FirstName: "Alex",
		LastName:  "Honnold",
		Email:     "  Climber@Ascension.APP ",
		Password:  "password123",
		Remember:  true,
	}

	form, err := req.IntoRegisterForm()
	if err != nil {
		t.Fatalf("IntoRegisterForm() error = %v", err)
	}
	if form.Username != "climber" || form.FirstName != "Alex" || form.LastName != "Honnold" {
		t.Errorf("IntoRegisterForm() names = %q %q %q", form.Username, form.FirstName, form.LastName)
	}
	if form.Email != "climber@ascension.app" {
		t.Errorf("Email = %q, want the normalized climber@ascension.app", form.Email)
	}
	if string(form.Password) != "password123" {
		t.Errorf("Password = %q, want password123", form.Password)
	}
}

func TestLoginFormBindingAndConversion(t *testing.T) {
	var form LoginForm
	if err := bindJSON(`{"identifier":"climber","password":"password123","remember":true}`, &form); err != nil {
		t.Fatalf("bind error = %v", err)
	}
	if !form.Remember {
		t.Error("Remember = false, want true")
	}

	login, err := form.IntoLoginForm()
	if err != nil {
		t.Fatalf("IntoLoginForm() error = %v", err)
	}
	if want := (model.LoginForm{Identifier: "climber", Password: model.UserPassword("password123")}); login.Identifier != want.Identifier || string(login.Password) != string(want.Password) {
		t.Errorf("IntoLoginForm() = %+v, want %+v", login, want)
	}

	for _, body := range []string{`{"password":"password123"}`, `{"identifier":"climber"}`, `{}`} {
		var form LoginForm
		if err := bindJSON(body, &form); err == nil {
			t.Errorf("bind(%s) = nil, want an error", body)
		}
	}
}

func TestRefreshTokenBinding(t *testing.T) {
	var token RefreshToken
	if err := bindJSON(`{"refresh_token":"abc"}`, &token); err != nil || token.Token != "abc" {
		t.Fatalf("bind = %v, token %q, want nil and abc", err, token.Token)
	}
	if err := bindJSON(`{}`, &RefreshToken{}); err == nil {
		t.Error("bind({}) = nil, want an error")
	}
}
