package utils

import (
	"errors"
	"net/http"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/inbound/http/dto/response"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog"
)

func Error(c *gin.Context, err error, loggers ...*zerolog.Logger) {
	if err == nil {
		return
	}

	reqID := c.GetString("request_id")
	for _, l := range loggers {
		l.Err(err).Str("request_id", reqID).Msg("")
	}

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
