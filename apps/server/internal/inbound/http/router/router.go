// @date 2026-03-20
// @file router.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package router

import (
	"net/http"
	"time"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/inbound/http/handler"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/inbound/http/middleware"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/setup/config"
	"github.com/gin-gonic/gin"
)

func New(
	app *gin.Engine,
	cfg config.Config,

	authMW middleware.AuthHandler,

	userH *handler.UserHandler,
	authH *handler.AuthHandler,
	videoH *handler.VideoHandler,
	analysisH *handler.AnalysisHandler,
) {
	app.Use(middleware.RequestID())
	app.Use(middleware.Logger())
	app.Use(middleware.Recovery())

	app.GET("/healthz", func(c *gin.Context) { c.Status(http.StatusNoContent) })

	v1 := app.Group("/v1")
	{
		authGroup := v1.Group("/auth")
		{
			authGroup.POST("/signup", middleware.RateLimiter(time.Minute, 5), authH.SignupLogin)
			authGroup.POST("/login", middleware.RateLimiter(time.Minute, 10), authH.Login)
			authGroup.DELETE("/logout", middleware.RateLimiter(time.Minute, 10), authMW(), authH.Logout)
			authGroup.PUT("/refresh", middleware.RateLimiter(time.Minute, 10), authH.RefreshToken)
		}

		usersGroup := v1.Group("/users", middleware.RateLimiter(time.Minute, 100), authMW(model.UserRoleAdmin))
		{
			usersGroup.POST("/", userH.Create)
			usersGroup.GET("/", userH.List)
			usersGroup.GET("/:id", userH.GetByID)
			usersGroup.PUT("/:id", userH.Update)
			usersGroup.DELETE("/:id", userH.Delete)
		}

		videosGroup := v1.Group("/videos", middleware.RateLimiter(time.Minute, 10), authMW(model.UserRoleAdmin, model.UserRoleUser))
		{
			videosGroup.GET("/upload-url", videoH.GetUploadURL)
			videosGroup.PUT("/upload-done/:id", videoH.UploadComplete)
			videosGroup.GET("/download-url/:id", videoH.GetDownloadURL)
		}

		analysesGroup := v1.Group("/analysis", middleware.RateLimiter(time.Minute, 10), authMW(model.UserRoleAdmin, model.UserRoleUser))
		{
			analysesGroup.POST("/", analysisH.Create)
			analysesGroup.GET("/:id", analysisH.GetByID)
		}
	}
}
