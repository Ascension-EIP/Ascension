// @date 2026-03-11
// @file username.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package model

import (
	"errors"
	"regexp"
)

// usernameRegex mirrors the chk_users_username_format database constraint.
var usernameRegex = regexp.MustCompile(`^[a-z0-9_]{3,30}$`)

var ErrUsernameInvalid = errors.New("invalid username: 3 to 30 lowercase letters, digits or underscores")

func ValidateUsername(username string) error {
	if !usernameRegex.MatchString(username) {
		return ErrUsernameInvalid
	}
	return nil
}
