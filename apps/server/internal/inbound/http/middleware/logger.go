package middleware

import (
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog"
)

func Logger(l *zerolog.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()

		c.Next()

		path := c.Request.URL.Path
		query := c.Request.URL.RawQuery
		method := c.Request.Method
		clientIP := c.ClientIP()
		latency := time.Since(start)
		status := c.Writer.Status()

		if query != "" {
			path = path + "?" + query
		}

		var event *zerolog.Event
		switch {
		case status >= 500:
			event = l.Error()
		case status >= 400:
			event = l.Warn()
		default:
			event = l.Info()
		}

		requestID, exists := c.Get("request_id")
		if !exists {
			requestID = "unknown"
		}

		event.
			Str("request_id", requestID.(string)).
			Str("ip", clientIP).
			Str("method", method).
			Str("path", path).
			Str("status", strconv.Itoa(status)).
			Str("latency", latency.String()).
			Msg("")

	}
}
