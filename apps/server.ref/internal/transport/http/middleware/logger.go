package middleware

import (
	"fmt"
	"time"

	"github.com/DimitriLaPoudre/go-backend-base/pkg/logger"
	"github.com/gin-gonic/gin"
)

const (
	green   = "\033[97;42m"
	white   = "\033[90;47m"
	yellow  = "\033[90;43m"
	red     = "\033[97;41m"
	blue    = "\033[97;44m"
	magenta = "\033[97;45m"
	cyan    = "\033[97;46m"
	reset   = "\033[0m"
)

func statusColor(code int) string {
	switch {
	case code >= 200 && code < 300:
		return green
	case code >= 300 && code < 400:
		return white
	case code >= 400 && code < 500:
		return yellow
	default:
		return red
	}
}

func methodColor(method string) string {
	switch method {
	case "GET":
		return blue
	case "POST":
		return cyan
	case "PUT":
		return yellow
	case "DELETE":
		return red
	case "PATCH":
		return green
	case "HEAD":
		return magenta
	case "OPTIONS":
		return white
	default:
		return reset
	}
}

func Logger(l *logger.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		path := c.Request.URL.Path
		query := c.Request.URL.RawQuery

		c.Next()

		latency := time.Since(start)
		status := c.Writer.Status()
		method := c.Request.Method
		clientIP := c.ClientIP()

		if query != "" {
			path = path + "?" + query
		}

		msg := fmt.Sprintf("|%s %3d %s| %13v | %15s |%s %-7s %s %s",
			statusColor(status), status, reset,
			latency,
			clientIP,
			methodColor(method), method, reset,
			path,
		)

		switch {
		case status >= 500:
			l.Error().Msg(msg)
		case status >= 400:
			l.Warn().Msg(msg)
		default:
			l.Info().Msg(msg)
		}
	}
}
