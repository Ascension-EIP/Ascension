package utils

import (
	"errors"
	"net/http"

	"github.com/DimitriLaPoudre/go-backend-base/internal/entity"
	"github.com/DimitriLaPoudre/go-backend-base/internal/transport/http/dto/response"
	"github.com/gin-gonic/gin"
)

func Error(c *gin.Context, err error) {
	if err == nil {
		return
	}

	switch {
	case errors.Is(err, entity.ErrInvalidInput),
		errors.Is(err, entity.ErrInvalidUsername),
		errors.Is(err, entity.ErrInvalidPassword),
		errors.Is(err, entity.ErrInvalidUserType):
		c.JSON(http.StatusBadRequest, response.Error{Error: err.Error()})
	case errors.Is(err, entity.ErrUnauthorized),
		errors.Is(err, entity.ErrTokenInvalid):
		c.JSON(http.StatusUnauthorized, response.Error{Error: err.Error()})
	case errors.Is(err, entity.ErrForbidden):
		c.JSON(http.StatusForbidden, response.Error{Error: err.Error()})
	case errors.Is(err, entity.ErrUserNotFound):
		c.JSON(http.StatusNotFound, response.Error{Error: err.Error()})
	case errors.Is(err, entity.ErrUsernameExists):
		c.JSON(http.StatusConflict, response.Error{Error: err.Error()})
	default:
		_ = c.Error(err)
		c.Status(http.StatusInternalServerError)
	}
}
