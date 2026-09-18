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
	ID        string `json:"id"`
	Username  string `json:"username"`
	FirstName string `json:"first_name"`
	LastName  string `json:"last_name"`
	Email     string `json:"email"`
	Role      string `json:"role"`
	Status    string `json:"status"`
}

func UserToResponse(user *model.User) *User {
	return &User{
		ID:        user.ID.String(),
		Username:  user.Username,
		FirstName: user.FirstName,
		LastName:  user.LastName,
		Email:     user.Email,
		Role:      string(user.Role),
		Status:    string(user.Status),
	}
}

func UsersToResponse(users []*model.User) []*User {
	r := []*User{}
	for _, user := range users {
		r = append(r, UserToResponse(user))
	}
	return r
}
