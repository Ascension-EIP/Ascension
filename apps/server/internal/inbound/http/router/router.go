package router

import (
	"net/http"
	"time"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/inbound/http/handler"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/inbound/http/middleware"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/setup/config"
	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog"
)

func New(
	app *gin.Engine,
	cfg *config.Config,
	l *zerolog.Logger,

	userH *handler.UserHandler,
	authH *handler.AuthHandler,
) {
	app.Use(middleware.RequestID())
	app.Use(middleware.Logger(l))
	app.Use(middleware.Recovery(l))
	gin.Recovery()

	app.GET("/healthz", func(c *gin.Context) { c.Status(http.StatusNoContent) })

	v1 := app.Group("/v1")
	{
		v1.POST("/signup", middleware.RateLimiter(time.Minute, 5), authH.Signup)
		v1.POST("/login", middleware.RateLimiter(time.Minute, 10), authH.Login)
		// v1.POST("/signup", middleware.RateLimiter(time.Minute, 5), guestMw, authH.Signup)
		// v1.POST("/login", middleware.RateLimiter(time.Minute, 10), guestMw, authH.Login)
		// v1.POST("/logout", middleware.RateLimiter(time.Minute, 10), authMw, authH.Logout)

		usersGroup := v1.Group("/users")
		{
			usersGroup.POST("/", middleware.RateLimiter(time.Minute, 25), userH.Create)
			usersGroup.GET("/", middleware.RateLimiter(time.Minute, 100), userH.List)
			usersGroup.GET("/:id", middleware.RateLimiter(time.Minute, 100), userH.GetByID)
			usersGroup.PUT("/:id", middleware.RateLimiter(time.Minute, 25), userH.Update)
			usersGroup.DELETE("/:id", middleware.RateLimiter(time.Minute, 25), userH.Delete)

			// usersGroup.POST("/", middleware.RateLimiter(time.Minute, 25), authMw, adminMw, userH.Create)
			// usersGroup.GET("/", middleware.RateLimiter(time.Minute, 100), authMw, adminMw, userH.List)
			// usersGroup.GET("/:id", middleware.RateLimiter(time.Minute, 100), authMw, adminMw, userH.GetByID)
			// usersGroup.PUT("/:id", middleware.RateLimiter(time.Minute, 25), authMw, adminMw, userH.Update)
			// usersGroup.DELETE("/:id", middleware.RateLimiter(time.Minute, 25), authMw, adminMw, userH.Delete)
		}
	}
}
