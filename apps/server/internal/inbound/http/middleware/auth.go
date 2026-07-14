package middleware

import (
	"net/http"
	"strings"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/service"
	"github.com/gin-gonic/gin"
)

func Auth(s *service.JWTService) gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" || !strings.HasPrefix(authHeader, "Bearer ") {
			c.AbortWithStatus(http.StatusUnauthorized)
			return
		}

		tokenStr := strings.TrimPrefix(authHeader, "Bearer ")

		claims, err := s.ValidateAccessToken(c.Request.Context(), tokenStr)
		if err != nil {
			c.AbortWithStatus(http.StatusUnauthorized)
			return
		}

		c.Set("userID", claims.UserID)
		c.Set("userRole", claims.UserRole)
		c.Next()
	}
}
