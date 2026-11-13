// @date 2026-09-09
// @file logger.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package middleware

import (
	"log/slog"
	"net/url"
	"time"

	"github.com/gin-gonic/gin"
)

func Logger() gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()

		c.Next()

		path := c.Request.URL.Path
		rawQuery := c.Request.URL.RawQuery
		method := c.Request.Method
		clientIP := c.ClientIP()
		userAgent := c.Request.UserAgent()

		query, _ := url.ParseQuery(rawQuery)

		latency := time.Since(start)
		status := c.Writer.Status()

		var level slog.Level
		switch {
		case status >= 500:
			level = slog.LevelError
		case status >= 400:
			level = slog.LevelInfo
		default:
			level = slog.LevelInfo
		}

		slog.LogAttrs(c.Request.Context(), level, "request_completed",
			slog.Group(
				"request",
				slog.String("method", method),
				slog.String("path", path),
				slog.Any("params", query),
				slog.String("ip", clientIP),
				slog.String("user_agent", userAgent),
			),
			slog.Group(
				"response",
				slog.Int("status", status),
				slog.Duration("latency", latency),
			),
		)
	}
}
