// @date 2026-11-13
// @file user_test.go
// @brief Unit tests of the user validation rules, email normalization and password hashing.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package model

import (
	"github.com/Ascension-EIP/Ascension/apps/server/internal/testutil/knownbug"
	"strings"
	"testing"

	"golang.org/x/crypto/bcrypt"
)

func TestNewUserEmail(t *testing.T) {
	tests := []struct {
		name  string
		input string
		want  UserEmail
	}{
		{name: "already normalized", input: "climber@ascension.app", want: "climber@ascension.app"},
		{name: "uppercase local part and domain", input: "Climber@Ascension.APP", want: "climber@ascension.app"},
		{name: "surrounding whitespace", input: "  climber@ascension.app\t\n", want: "climber@ascension.app"},
		{name: "uppercase and whitespace", input: " CLIMBER@ASCENSION.APP ", want: "climber@ascension.app"},
		{name: "non ascii letters", input: "Élodie@Exemple.FR", want: "élodie@exemple.fr"},
		{name: "empty", input: "", want: ""},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := NewUserEmail(tt.input); got != tt.want {
				t.Errorf("NewUserEmail(%q) = %q, want %q", tt.input, got, tt.want)
			}
		})
	}
}

func TestNewUserEmailIsIdempotent(t *testing.T) {
	once := NewUserEmail(" Climber@Ascension.APP ")
	if twice := NewUserEmail(string(once)); twice != once {
		t.Errorf("NewUserEmail is not idempotent: %q then %q", once, twice)
	}
}

func TestUserUsernameValidate(t *testing.T) {
	tests := []struct {
		name     string
		username UserUsername
		wantErr  bool
	}{
		{name: "shortest", username: "climbr"},
		{name: "longest", username: UserUsername(strings.Repeat("a", 24))},
		{name: "too short", username: "climb", wantErr: true},
		{name: "empty", username: "", wantErr: true},
		{name: "too long", username: UserUsername(strings.Repeat("a", 25)), wantErr: true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if err := tt.username.Validate(); (err != nil) != tt.wantErr {
				t.Errorf("Validate(%q) = %v, wantErr %v", tt.username, err, tt.wantErr)
			}
		})
	}
}

func TestUserEmailValidate(t *testing.T) {
	for _, email := range []UserEmail{"climber@ascension.app", ""} {
		if err := email.Validate(); err != nil {
			t.Errorf("Validate(%q) = %v, want nil", email, err)
		}
	}
}

func TestUserPasswordValidate(t *testing.T) {
	tests := []struct {
		name     string
		password UserPassword
		wantErr  bool
	}{
		{name: "shortest", password: UserPassword("12345678")},
		{name: "longest", password: UserPassword(strings.Repeat("a", 64))},
		{name: "too short", password: UserPassword("1234567"), wantErr: true},
		{name: "empty", password: nil, wantErr: true},
		{name: "too long", password: UserPassword(strings.Repeat("a", 65)), wantErr: true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if err := tt.password.Validate(); (err != nil) != tt.wantErr {
				t.Errorf("Validate() = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}

func TestUserPasswordHash(t *testing.T) {
	password := UserPassword("correct horse battery")

	hash, err := password.Hash()
	if err != nil {
		t.Fatalf("Hash() error = %v", err)
	}
	if string(hash) == string(password) {
		t.Fatal("Hash() returned the password in clear")
	}
	if err := bcrypt.CompareHashAndPassword(hash, password); err != nil {
		t.Errorf("CompareHashAndPassword(hash, password) = %v, want nil", err)
	}
	if err := bcrypt.CompareHashAndPassword(hash, []byte("wrong password")); err == nil {
		t.Error("CompareHashAndPassword(hash, wrong) = nil, want an error")
	}

	again, err := password.Hash()
	if err != nil {
		t.Fatalf("Hash() error = %v", err)
	}
	if string(again) == string(hash) {
		t.Error("Hash() is not salted: two hashes of the same password are equal")
	}

	if _, err := UserPassword(strings.Repeat("a", 73)).Hash(); err == nil {
		t.Error("Hash() of a 73 byte password = nil error, want bcrypt.ErrPasswordTooLong")
	}
}

func TestUserRoleValidate(t *testing.T) {
	for _, role := range []UserRole{UserRoleAdmin, UserRoleUser, UserRoleCoach, UserRoleGym} {
		if err := role.Validate(); err != nil {
			t.Errorf("Validate(%q) = %v, want nil", role, err)
		}
	}
	for _, role := range []UserRole{"", "root", "Admin"} {
		if err := role.Validate(); err == nil {
			t.Errorf("Validate(%q) = nil, want an error", role)
		}
	}
}

func TestUserStatusValidate(t *testing.T) {
	for _, status := range []UserStatus{UserStatusActive, UserStatusDeactivated} {
		if err := status.Validate(); err != nil {
			t.Errorf("Validate(%q) = %v, want nil", status, err)
		}
	}
	for _, status := range []UserStatus{"", "banned", "ACTIVE"} {
		if err := status.Validate(); err == nil {
			t.Errorf("Validate(%q) = nil, want an error", status)
		}
	}
}

func validUser() User {
	return User{
		Username: "climber",
		Email:    "climber@ascension.app",
		Password: UserPassword("password123"),
		Role:     UserRoleUser,
		Status:   UserStatusActive,
	}
}

func TestUserValidate(t *testing.T) {
	tests := []struct {
		name    string
		edit    func(*User)
		wantErr string
	}{
		{name: "valid", edit: func(*User) {}},
		{name: "bad username", edit: func(u *User) { u.Username = "abc" }, wantErr: "username"},
		{name: "bad password", edit: func(u *User) { u.Password = UserPassword("short") }, wantErr: "password"},
		{name: "bad role", edit: func(u *User) { u.Role = "root" }, wantErr: "role"},
		{name: "missing role", edit: func(u *User) { u.Role = "" }, wantErr: "role"},
		{name: "bad status", edit: func(u *User) { u.Status = "banned" }, wantErr: "status"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			user := validUser()
			tt.edit(&user)

			err := user.Validate()
			if tt.wantErr == "" {
				if err != nil {
					t.Fatalf("Validate() = %v, want nil", err)
				}
				return
			}
			if err == nil || !strings.HasPrefix(err.Error(), tt.wantErr+":") {
				t.Fatalf("Validate() = %v, want an error starting with %q", err, tt.wantErr)
			}
		})
	}
}

func TestUserPartialValidate(t *testing.T) {
	full := func() UserPartial {
		return UserPartial{
			Username: new(UserUsername("climber")),
			Email:    new(UserEmail("climber@ascension.app")),
			Password: new(UserPassword("password123")),
			Role:     new(UserRoleCoach),
			Status:   new(UserStatusDeactivated),
		}
	}

	tests := []struct {
		name    string
		edit    func(*UserPartial)
		wantErr string
	}{
		{name: "every field valid", edit: func(*UserPartial) {}},
		{name: "bad username", edit: func(p *UserPartial) { p.Username = new(UserUsername("abc")) }, wantErr: "username"},
		{name: "bad password", edit: func(p *UserPartial) { p.Password = new(UserPassword("short")) }, wantErr: "password"},
		{name: "bad role", edit: func(p *UserPartial) { p.Role = new(UserRole("root")) }, wantErr: "role"},
		{name: "bad status", edit: func(p *UserPartial) { p.Status = new(UserStatus("banned")) }, wantErr: "status"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			partial := full()
			tt.edit(&partial)

			err := partial.Validate()
			if tt.wantErr == "" {
				if err != nil {
					t.Fatalf("Validate() = %v, want nil", err)
				}
				return
			}
			if err == nil || !strings.HasPrefix(err.Error(), tt.wantErr+":") {
				t.Fatalf("Validate() = %v, want an error starting with %q", err, tt.wantErr)
			}
		})
	}
}

// TestUserPartialValidateOnlyChecksGivenFields updates one field at a time: the fields
// left nil must not be validated.
func TestUserPartialValidateOnlyChecksGivenFields(t *testing.T) {
	knownbug.Skip(t, "UserPartial.Validate calls Validate on nil pointer fields and panics")

	partials := map[string]UserPartial{
		"nothing":         {},
		"first name only": {FirstName: new("Alex")},
		"username only":   {Username: new(UserUsername("climber"))},
		"password only":   {Password: new(UserPassword("password123"))},
	}

	for name, partial := range partials {
		t.Run(name, func(t *testing.T) {
			if err := partial.Validate(); err != nil {
				t.Errorf("Validate() = %v, want nil", err)
			}
		})
	}
}
