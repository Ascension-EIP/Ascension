package middleware

import (
	"fmt"
	"net/http"
	"runtime/debug"

	"github.com/DimitriLaPoudre/go-backend-base/pkg/logger"
	"github.com/gin-gonic/gin"
)

func Recovery(l *logger.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		defer func() {
			if err := recover(); err != nil {
				stack := string(debug.Stack())

				l.Error().
					Str("error", fmt.Sprintf("%v", err)).
					Str("ip", c.ClientIP()).
					Str("method", c.Request.Method).
					Str("path", c.Request.URL.Path).
					Msg("panic recovered\n" + stack)

				c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{
					"error": "Internal Server Panic",
				})
			}
		}()
		c.Next()
	}
}
