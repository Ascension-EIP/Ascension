package router

import (
	"net/http"
	"time"

	"github.com/DimitriLaPoudre/go-backend-base/internal/infra/config"
	"github.com/DimitriLaPoudre/go-backend-base/internal/repo"
	"github.com/DimitriLaPoudre/go-backend-base/internal/transport/http/handler"
	"github.com/DimitriLaPoudre/go-backend-base/internal/transport/http/middleware"
	"github.com/DimitriLaPoudre/go-backend-base/pkg/logger"
	"github.com/gin-gonic/gin"
)

func New(
	app *gin.Engine,
	cfg *config.Config,
	l *logger.Logger,
	repo *repo.Repo,

	guestMw gin.HandlerFunc,
	authMw gin.HandlerFunc,
	adminMw gin.HandlerFunc,
	userMw gin.HandlerFunc,

	authH *handler.AuthHandler,
	userH *handler.UserHandler,
) {
	app.Use(middleware.Logger(l))
	app.Use(middleware.Recovery(l))

	app.GET("/healthz", func(c *gin.Context) { c.Status(http.StatusNoContent) })

	v1 := app.Group("/v1")
	{
		v1.POST("/signup", middleware.RateLimiter(time.Minute, 5), guestMw, authH.Signup)
		v1.POST("/login", middleware.RateLimiter(time.Minute, 10), guestMw, authH.Login)
		v1.POST("/logout", middleware.RateLimiter(time.Minute, 10), authMw, authH.Logout)

		usersGroup := v1.Group("/users")
		{
			usersGroup.POST("/", middleware.RateLimiter(time.Minute, 25), authMw, adminMw, userH.Create)
			usersGroup.GET("/", middleware.RateLimiter(time.Minute, 100), authMw, adminMw, userH.List)
			usersGroup.GET("/:id", middleware.RateLimiter(time.Minute, 100), authMw, adminMw, userH.GetByID)
			usersGroup.PUT("/:id", middleware.RateLimiter(time.Minute, 25), authMw, adminMw, userH.Update)
			usersGroup.DELETE("/:id", middleware.RateLimiter(time.Minute, 25), authMw, adminMw, userH.Delete)
		}
	}
}
