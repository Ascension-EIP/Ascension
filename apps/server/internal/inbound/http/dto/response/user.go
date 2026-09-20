// @date 2026-03-11
// @file user.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package response

import "github.com/Ascension-EIP/Ascension/apps/server/internal/model"

type User struct {
	ID        string
	Username  model.UserUsername
	FirstName string
	LastName  string
	Email     model.UserEmail
	Role      model.UserRole
	Status    model.UserStatus
}

func UserToResponse(user model.User) User {
	return User{
		ID:        user.ID.String(),
		Username:  user.Username,
		FirstName: user.FirstName,
		LastName:  user.LastName,
		Email:     user.Email,
		Role:      user.Role,
		Status:    user.Status,
	}
}

func UsersToResponse(users []model.User) []User {
	r := make([]User, 0, len(users))
	for _, user := range users {
		r = append(r, UserToResponse(user))
	}

	return r
}
