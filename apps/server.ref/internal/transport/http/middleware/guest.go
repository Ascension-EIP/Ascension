package middleware

import (
	"net/http"

	"github.com/DimitriLaPoudre/go-backend-base/internal/infra/config"
	"github.com/DimitriLaPoudre/go-backend-base/internal/service/auth"
	"github.com/gin-gonic/gin"
)

func Guest(cfg *config.Config, s *auth.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		sessionID, err := c.Cookie(cfg.Auth.CookieName)
		if err != nil {
			c.Next()
			return
		}

		if _, err := s.ValidateSession(c.Request.Context(), sessionID); err != nil {
			c.SetCookie(cfg.Auth.CookieName, "", -1, "/", "", false, true)
			c.Next()
			return
		}
		c.AbortWithStatus(http.StatusForbidden)
	}
}
