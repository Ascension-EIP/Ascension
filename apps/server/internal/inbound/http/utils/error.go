// @date 2026-03-11
// @file error.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package utils

import (
	"errors"
	"log/slog"
	"net/http"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/inbound/http/dto/response"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/gin-gonic/gin"
)

func Error(c *gin.Context, err error) {
	if err == nil {
		return
	}

	slog.ErrorContext(c.Request.Context(), "handler forward domain error", slog.String("err", err.Error()))

	switch {
	case errors.Is(err, model.ErrRoleInvalid):
		c.JSON(http.StatusUnprocessableEntity, response.Error{Message: err.Error()})
	case errors.Is(err, model.ErrEmailDuplicate):
		c.JSON(http.StatusConflict, response.Error{Message: err.Error()})
	case errors.Is(err, model.ErrUserNotFound):
		c.JSON(http.StatusNotFound, response.Error{Message: err.Error()})
	default:
		_ = c.Error(err)
		c.JSON(http.StatusInternalServerError, response.Error{Message: err.Error()})
	}
}
