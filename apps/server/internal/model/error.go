package model

import "errors"

// var (
// 	ErrUserNotFound    = errors.New("user not found")
// 	ErrInvalidUsername = errors.New("invalid username")
// 	ErrInvalidPassword = errors.New("invalid password")
// 	ErrUsernameExists  = errors.New("username already exists")
// 	ErrInvalidUserType = errors.New("invalid user type")
// 	ErrUnauthorized    = errors.New("unauthorized")
// 	ErrForbidden       = errors.New("forbidden")
// 	ErrInvalidInput    = errors.New("invalid input")
// 	ErrTokenInvalid    = errors.New("token invalid")
// )

var (
	ErrEmailDuplicate = errors.New("email already exists")
	ErrUserNotFound   = errors.New("user not found")
	ErrUnknown        = errors.New("unknown error")
)
