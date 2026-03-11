package middleware

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

func RequestID() gin.HandlerFunc {
	return func(c *gin.Context) {
		requestID := "unknown"
		if requestUUID, err := uuid.NewV7(); err == nil {
			requestID = requestUUID.String()
		}
		c.Set("request_id", requestID)
		c.Header("X-Request-ID", requestID)
		c.Next()
	}
}
