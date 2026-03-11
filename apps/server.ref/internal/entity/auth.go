package entity

import "time"

type Session struct {
	ID        string
	UserID    uint
	ExpiresAt time.Time
	CreatedAt time.Time
	UpdatedAt time.Time
}

type AuthForm struct {
	Username string
	Password string
}
