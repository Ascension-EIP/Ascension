// @date 2026-09-20
// @file auth.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package middleware

import (
	"net/http"
	"slices"
	"strings"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/inbound/http/macro"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/service"
	"github.com/gin-gonic/gin"
)

type AuthHandler func(roles ...model.UserRole) gin.HandlerFunc

func AuthMiddleware(s *service.JWTService) AuthHandler {
	return func(roles ...model.UserRole) gin.HandlerFunc {
		return func(c *gin.Context) {
			authHeader := c.GetHeader("Authorization")
			if !strings.HasPrefix(authHeader, "Bearer ") {
				c.AbortWithStatus(http.StatusUnauthorized)
				return
			}

			tokenStr := strings.TrimPrefix(authHeader, "Bearer ")

			claims, err := s.ValidateAccessToken(c.Request.Context(), tokenStr)
			if err != nil {
				c.AbortWithStatus(http.StatusUnauthorized)
				return
			}

			if len(roles) != 0 && !slices.Contains(roles, claims.UserRole) {
				c.AbortWithStatus(http.StatusUnauthorized)
			}
			c.Set(macro.Me, model.User{
				ID:        claims.UserID,
				Username:  claims.UserUsername,
				FirstName: claims.UserFirstName,
				LastName:  claims.UserLastName,
				Email:     claims.UserEmail,
				Role:      claims.UserRole,
			})
			c.Next()
		}
	}
}
