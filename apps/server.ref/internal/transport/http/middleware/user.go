package middleware

import (
	"errors"
	"net/http"

	"github.com/DimitriLaPoudre/go-backend-base/internal/entity"
	"github.com/DimitriLaPoudre/go-backend-base/internal/service/user"
	"github.com/DimitriLaPoudre/go-backend-base/internal/transport/http/utils"
	"github.com/gin-gonic/gin"
)

func User(s *user.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID, err := utils.GetFromContext[uint](c, "userID")
		if err != nil {
			c.AbortWithStatus(http.StatusUnauthorized)
			return
		}
		if err := s.IsUser(c.Request.Context(), userID); err != nil {
			switch {
			case errors.Is(err, entity.ErrForbidden):
				c.AbortWithStatus(http.StatusForbidden)
			case errors.Is(err, entity.ErrUserNotFound):
				c.AbortWithStatus(http.StatusUnauthorized)
			default:
				c.AbortWithStatus(http.StatusInternalServerError)
			}
			return
		}
		c.Next()
	}
}
