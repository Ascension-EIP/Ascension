package response

import "github.com/Ascension-EIP/Ascension/apps/server/internal/model"

type User struct {
	ID    string
	Name  string
	Email string
	Role  string
}

func UserToResponse(user *model.User) *User {
	return &User{
		ID:    user.ID.String(),
		Name:  user.Name,
		Email: user.Email,
		Role:  string(user.Role),
	}
}

func UsersToResponse(users []*model.User) []*User {
	r := []*User{}
	for _, user := range users {
		r = append(r, UserToResponse(user))
	}
	return r
}
