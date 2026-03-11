package auth

import (
	"regexp"

	"github.com/DimitriLaPoudre/go-backend-base/internal/entity"
)

var (
	regexUsername = regexp.MustCompile(`^[a-zA-Z0-9_]+$`)
	regexPassword = regexp.MustCompile(`^[a-zA-Z0-9!@#\$%\^&\*\(\)_\+\-=\[\]\{\};:'",.<>/?\\|]+$`)
)

func validateUsername(username string) error {
	if len(username) < 3 || len(username) > 32 {
		return entity.ErrInvalidUsername
		// return fmt.Errorf("validateUsername: %w", errors.New("username must be between 3 and 32 characters long"))
	}
	if !regexUsername.MatchString(username) {
		return entity.ErrInvalidUsername
		// return fmt.Errorf("validateUsername: %w", errors.New("username must only contain alphanumeric characters, _, -"))
	}
	return nil
}

func validatePassword(password string) error {
	if len(password) < 8 || len(password) > 128 {
		return entity.ErrInvalidPassword
		// return fmt.Errorf("validatePassword: %w", errors.New("password must be between 8 and 128 characters long"))
	}
	if !regexPassword.MatchString(password) {
		return entity.ErrInvalidPassword
		// return fmt.Errorf("validatePassword: %w", errors.New("password contains invalid character"))
	}
	return nil
}
