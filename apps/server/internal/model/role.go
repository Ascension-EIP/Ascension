package model

import (
	"database/sql/driver"
	"encoding/json"
	"errors"
	"fmt"
)

type UserRole string

const (
	UserRoleAdmin UserRole = "admin"
	UserRoleUser  UserRole = "user"
)

var (
	ErrRoleInvalid = errors.New("invalid role")
)

func (r UserRole) IsValid() bool {
	switch r {
	case UserRoleAdmin, UserRoleUser:
		return true
	}
	return false
}

func (r *UserRole) UnmarshalJSON(data []byte) error {
	var s string
	if err := json.Unmarshal(data, &s); err != nil {
		return err
	}

	role := UserRole(s)
	if !role.IsValid() {
		return fmt.Errorf("invalid role: %s", s)
	}

	*r = role
	return nil
}

func (r UserRole) MarshalJSON() ([]byte, error) {
	if !r.IsValid() {
		return nil, fmt.Errorf("invalid role: %s", r)
	}
	return json.Marshal(string(r))
}

func (r *UserRole) Scan(value interface{}) error {
	if value == nil {
		return fmt.Errorf("role cannot be null")
	}

	var str string
	switch v := value.(type) {
	case string:
		str = v
	case []byte:
		str = string(v)
	default:
		return fmt.Errorf("cannot scan %T into UserRole", value)
	}

	role := UserRole(str)
	if !role.IsValid() {
		return fmt.Errorf("invalid role from DB: %s", str)
	}

	*r = role
	return nil
}

func (r UserRole) Value() (driver.Value, error) {
	if !r.IsValid() {
		return nil, fmt.Errorf("invalid role: %s", r)
	}
	return string(r), nil
}

func (r UserRole) String() string {
	return string(r)
}
