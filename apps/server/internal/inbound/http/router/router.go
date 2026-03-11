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

	authMW gin.HandlerFunc,
	guestMW gin.HandlerFunc,
	adminMW gin.HandlerFunc,
	userMW gin.HandlerFunc,

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
		v1.POST("/signup", middleware.RateLimiter(time.Minute, 5), guestMW, authH.Signup)
		v1.POST("/login", middleware.RateLimiter(time.Minute, 10), guestMW, authH.Login)
		v1.DELETE("/logout", middleware.RateLimiter(time.Minute, 10), authH.Logout)
		v1.PUT("/refresh", middleware.RateLimiter(time.Minute, 10), authH.RefreshToken)

		usersGroup := v1.Group("/users")
		{
			usersGroup.POST("/", middleware.RateLimiter(time.Minute, 25), authMW, adminMW, userH.Create)
			usersGroup.GET("/", middleware.RateLimiter(time.Minute, 100), authMW, adminMW, userH.List)
			usersGroup.GET("/:id", middleware.RateLimiter(time.Minute, 100), authMW, adminMW, userH.GetByID)
			usersGroup.PUT("/:id", middleware.RateLimiter(time.Minute, 25), authMW, adminMW, userH.Update)
			usersGroup.DELETE("/:id", middleware.RateLimiter(time.Minute, 25), authMW, adminMW, userH.Delete)
		}
	}
}
