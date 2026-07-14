package middleware

import (
	"net/http"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/inbound/http/utils"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/gin-gonic/gin"
)

func Admin() gin.HandlerFunc {
	return func(c *gin.Context) {
		role, err := utils.GetFromContext[model.UserRole](c, "userRole")
		if err != nil || role != model.UserRoleAdmin {
			c.AbortWithStatus(http.StatusForbidden)
			return
		}

		c.Next()
	}
}

func User() gin.HandlerFunc {
	return func(c *gin.Context) {
		role, err := utils.GetFromContext[model.UserRole](c, "userRole")
		if err != nil || !role.IsValid() {
			c.AbortWithStatus(http.StatusForbidden)
			return
		}

		c.Next()
	}
}
