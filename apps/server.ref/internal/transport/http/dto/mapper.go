package dto

import (
	"strconv"
	"time"

	"github.com/DimitriLaPoudre/go-backend-base/internal/entity"
	"github.com/DimitriLaPoudre/go-backend-base/internal/transport/http/dto/request"
	"github.com/DimitriLaPoudre/go-backend-base/internal/transport/http/dto/response"
)

// Request to Entity mappers

func CreateUserToEntity(req *request.CreateUser) *entity.User {
	if req == nil {
		return nil
	}
	return &entity.User{
		Username: req.Username,
		Password: req.Password,
		Type:     req.Type,
	}
}

func UpdateUserToEntity(id uint, req *request.UpdateUser) *entity.User {
	if req == nil {
		return nil
	}
	return &entity.User{
		ID:       id,
		Username: req.Username,
		Password: req.Password,
		Type:     req.Type,
	}
}

func AuthFormToEntity(req *request.AuthForm) *entity.AuthForm {
	if req == nil {
		return nil
	}
	return &entity.AuthForm{
		Username: req.Username,
		Password: req.Password,
	}
}

// Entity to Response mappers

func UserToResponse(e *entity.User) *response.User {
	if e == nil {
		return nil
	}
	return &response.User{
		ID:        strconv.FormatUint(uint64(e.ID), 10),
		Username:  e.Username,
		Type:      e.Type,
		CreatedAt: e.CreatedAt.Format(time.RFC3339),
		UpdatedAt: e.UpdatedAt.Format(time.RFC3339),
	}
}

func UsersToResponse(entities []entity.User) []response.User {
	responses := make([]response.User, len(entities))
	for i, e := range entities {
		responses[i] = *UserToResponse(&e)
	}
	return responses
}
