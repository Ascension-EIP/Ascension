// @date 2026-11-13
// @file user_test.go
// @brief Unit tests of the user creation and update request DTOs.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package request

import (
	"testing"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"uuid"
)

func TestCreateUserBindingAndConversion(t *testing.T) {
	var req CreateUser
	body := `{"username":"climber","first_name":"Alex","last_name":"Honnold","email":" Climber@Ascension.APP","password":"password123","role":"coach"}`
	if err := bindJSON(body, &req); err != nil {
		t.Fatalf("bind error = %v", err)
	}

	user, err := req.IntoUser()
	if err != nil {
		t.Fatalf("IntoUser() error = %v", err)
	}
	want := model.User{
		Username:  "climber",
		FirstName: "Alex",
		LastName:  "Honnold",
		Email:     "climber@ascension.app",
		Password:  model.UserPassword("password123"),
		Role:      model.UserRoleCoach,
		Status:    model.UserStatusActive,
	}
	if user.Username != want.Username || user.FirstName != want.FirstName || user.LastName != want.LastName ||
		user.Email != want.Email || string(user.Password) != string(want.Password) || user.Role != want.Role || user.Status != want.Status {
		t.Errorf("IntoUser() = %+v, want %+v", user, want)
	}

	for _, field := range []string{"username", "first_name", "last_name", "email", "password", "role"} {
		t.Run("missing "+field, func(t *testing.T) {
			fields := map[string]string{"username": "climber", "first_name": "Alex", "last_name": "Honnold", "email": "a@b.c", "password": "password123", "role": "user"}
			delete(fields, field)
			body := "{"
			for k, v := range fields {
				if body != "{" {
					body += ","
				}
				body += `"` + k + `":"` + v + `"`
			}
			body += "}"

			if err := bindJSON(body, &CreateUser{}); err == nil {
				t.Errorf("bind(%s) = nil, want an error", body)
			}
		})
	}
}

func TestUpdateUserIntoUserPartial(t *testing.T) {
	id := uuid.NewV7()

	t.Run("no field", func(t *testing.T) {
		partial, err := (&UpdateUser{}).IntoUserPartial(id.String())
		if err != nil {
			t.Fatalf("IntoUserPartial() error = %v", err)
		}
		if partial != (model.UserPartial{ID: id}) {
			t.Errorf("IntoUserPartial() = %+v, want only the ID", partial)
		}
	})

	t.Run("every field", func(t *testing.T) {
		req := UpdateUser{
			Username:  new("climber"),
			FirstName: new("Alex"),
			LastName:  new("Honnold"),
			Email:     new(" Climber@Ascension.APP "),
			Password:  new("password123"),
			Role:      new("admin"),
			Status:    new("deactivated"),
		}
		partial, err := req.IntoUserPartial(id.String())
		if err != nil {
			t.Fatalf("IntoUserPartial() error = %v", err)
		}
		if partial.ID != id {
			t.Errorf("ID = %v, want %v", partial.ID, id)
		}
		if *partial.Username != "climber" || *partial.FirstName != "Alex" || *partial.LastName != "Honnold" {
			t.Errorf("names = %q %q %q", *partial.Username, *partial.FirstName, *partial.LastName)
		}
		if *partial.Email != "climber@ascension.app" {
			t.Errorf("Email = %q, want the normalized climber@ascension.app", *partial.Email)
		}
		if string(*partial.Password) != "password123" || *partial.Role != model.UserRoleAdmin || *partial.Status != model.UserStatusDeactivated {
			t.Errorf("password/role/status = %q %q %q", *partial.Password, *partial.Role, *partial.Status)
		}
	})

	t.Run("copies the values", func(t *testing.T) {
		firstName := "Alex"
		partial, err := (&UpdateUser{FirstName: &firstName}).IntoUserPartial(id.String())
		if err != nil {
			t.Fatalf("IntoUserPartial() error = %v", err)
		}
		firstName = "changed"
		if *partial.FirstName != "Alex" {
			t.Errorf("FirstName = %q, want Alex: the partial shares the request memory", *partial.FirstName)
		}
	})

	t.Run("invalid id", func(t *testing.T) {
		if _, err := (&UpdateUser{}).IntoUserPartial("not-a-uuid"); err == nil {
			t.Error("IntoUserPartial(not-a-uuid) = nil error, want an error")
		}
	})
}
