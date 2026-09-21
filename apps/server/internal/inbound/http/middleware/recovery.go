// @date 2026-09-09
// @file recovery.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package middleware

import (
	"errors"
	"log/slog"
	"net"
	"net/http"
	"net/url"
	"os"
	"runtime/debug"
	"strings"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/inbound/http/dto/response"
	"github.com/gin-gonic/gin"
)

func isBrokenPipe(err any) bool {
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

func Recovery() gin.HandlerFunc {
	return func(c *gin.Context) {
		defer func() {
			if err := recover(); err != nil {
				path := c.Request.URL.Path
				rawQuery := c.Request.URL.RawQuery
				method := c.Request.Method
				clientIP := c.ClientIP()
				userAgent := c.Request.UserAgent()

				query, _ := url.ParseQuery(rawQuery)

				if isBrokenPipe(err) {

					slog.LogAttrs(c.Request.Context(), slog.LevelError, "client connection broken",
						slog.Group(
							"request",
							slog.String("method", method),
							slog.String("path", path),
							slog.Any("params", query),
							slog.String("ip", clientIP),
							slog.String("user_agent", userAgent),
						),
						slog.String("stack", string(debug.Stack())),
					)

					c.Abort()
					return
				}

				slog.LogAttrs(c.Request.Context(), slog.LevelError, "panic recovered",
					slog.Group(
						"request",
						slog.String("method", method),
						slog.String("path", path),
						slog.Any("params", query),
						slog.String("ip", clientIP),
						slog.String("user_agent", userAgent),
					),
					slog.String("stack", string(debug.Stack())),
				)

				c.AbortWithStatusJSON(
					http.StatusInternalServerError,
					response.Error{Message: "Internal server error"},
				)
				return
			}
		}()

		c.Next()
	}
}
