package middleware

import (
	"errors"
	"net"
	"net/http"
	"os"
	"runtime/debug"
	"strings"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/inbound/http/dto/response"
	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog"
)

func isBrokenPipe(err interface{}) bool {
	if ne, ok := err.(*net.OpError); ok {
		var se *os.SyscallError
		if errors.As(ne, &se) {
			errStr := strings.ToLower(se.Error())

			if strings.Contains(errStr, "broken pipe") {
				return true
			}

			if strings.Contains(errStr, "connection reset by peer") {
				return true
			}

			if strings.Contains(errStr, "connection aborted") {
				return true
			}
		}
	}
	return false
}

func Recovery(logger *zerolog.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		defer func() {
			if err := recover(); err != nil {
				requestID, exists := c.Get("request_id")
				if !exists {
					requestID = "unknown"
				}

				if isBrokenPipe(err) {
					logger.Warn().
						Str("request_id", requestID.(string)).
						Str("method", c.Request.Method).
						Str("path", c.Request.URL.Path).
						Str("ip", c.ClientIP()).
						Interface("error", err).
						Msg("client connection broken")

					c.Abort()
					return
				}

				stack := string(debug.Stack())

				logger.Error().
					Str("request_id", requestID.(string)).
					Str("method", c.Request.Method).
					Str("path", c.Request.URL.Path).
					Str("ip", c.ClientIP()).
					Interface("error", err).
					Str("stack", stack).
					Msg("panic recovered")

				c.AbortWithStatusJSON(http.StatusInternalServerError, response.Error{Message: "Internal server error"})
			}
		}()

		c.Next()
	}
}
