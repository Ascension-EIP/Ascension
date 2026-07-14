package middleware

import (
	"net/http"
	"strings"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/service"
	"github.com/gin-gonic/gin"
)

func Guest(s *service.JWTService) gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader != "" && strings.HasPrefix(authHeader, "Bearer ") {
			tokenStr := strings.TrimPrefix(authHeader, "Bearer ")
			_, err := s.ValidateAccessToken(c.Request.Context(), tokenStr)
			if err == nil {
				c.AbortWithStatus(http.StatusForbidden)
				return
			}
		}

		c.Next()
	}
}
