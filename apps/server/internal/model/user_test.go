// @date 2026-09-17
// @file user_test.go
// @brief File description.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package model

import "testing"

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
