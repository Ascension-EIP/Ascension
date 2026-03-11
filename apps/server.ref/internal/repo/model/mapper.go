package model

import "github.com/DimitriLaPoudre/go-backend-base/internal/entity"

func UserToEntity(m *User) *entity.User {
	if m == nil {
		return nil
	}
	return &entity.User{
		ID:        m.ID,
		Type:      m.Type,
		Username:  m.Username,
		Password:  m.Password,
		CreatedAt: m.CreatedAt,
		UpdatedAt: m.UpdatedAt,
	}
}

func UserFromEntity(e *entity.User) *User {
	if e == nil {
		return nil
	}
	return &User{
		ID:        e.ID,
		Type:      e.Type,
		Username:  e.Username,
		Password:  e.Password,
		CreatedAt: e.CreatedAt,
		UpdatedAt: e.UpdatedAt,
	}
}

func UsersToEntity(models []User) []entity.User {
	entities := make([]entity.User, len(models))
	for i, m := range models {
		entities[i] = *UserToEntity(&m)
	}
	return entities
}

func SessionToEntity(m *Session) *entity.Session {
	if m == nil {
		return nil
	}
	return &entity.Session{
		ID:        m.ID,
		UserID:    m.UserID,
		ExpiresAt: m.ExpiresAt,
		CreatedAt: m.CreatedAt,
		UpdatedAt: m.UpdatedAt,
	}
}

func SessionFromEntity(e *entity.Session) *Session {
	if e == nil {
		return nil
	}
	return &Session{
		ID:        e.ID,
		UserID:    e.UserID,
		ExpiresAt: e.ExpiresAt,
		CreatedAt: e.CreatedAt,
		UpdatedAt: e.UpdatedAt,
	}
}
