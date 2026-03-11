package entity

import "time"

const (
	UserTypeAdmin = "admin"
	UserTypeUser  = "user"
)

type (
	User struct {
		ID        uint
		Type      string
		Username  string
		Password  string
		CreatedAt time.Time
		UpdatedAt time.Time
	}
)
