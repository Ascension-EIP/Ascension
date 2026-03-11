package middleware

import (
	"net/http"

	"github.com/DimitriLaPoudre/go-backend-base/internal/infra/config"
	"github.com/DimitriLaPoudre/go-backend-base/internal/service/auth"
	"github.com/gin-gonic/gin"
)

func Auth(cfg *config.Config, s *auth.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		sessionID, err := c.Cookie(cfg.Auth.CookieName)
		if err != nil {
			c.AbortWithStatus(http.StatusUnauthorized)
			return
		}

		userID, err := s.ValidateSession(c.Request.Context(), sessionID)
		if err != nil {
			c.SetCookie(cfg.Auth.CookieName, "", -1, "/", "", false, true)
			c.AbortWithStatus(http.StatusUnauthorized)
			return
		}

		if err := s.RefreshSession(c.Request.Context(), sessionID); err == nil {
			c.SetCookie(cfg.Auth.CookieName, sessionID, int(cfg.Auth.CookieExp.Seconds()), "/", "", cfg.HTTP.HTTPS, true)
		}

		c.Set("userID", userID)
		c.Next()
	}
}
