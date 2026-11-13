// @date 2026-11-13
// @file router.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>, Nicolas TORO <nicolas.toro@epitech.eu>, Christophe Vandevoir <christophe.vandevoir@epitech.eu>
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
	profileH *handler.ProfileHandler,
	climbingSessionH *handler.ClimbingSessionHandler,
	bodyConstraintH *handler.UserBodyConstraintHandler,
	friendshipH *handler.FriendshipHandler,
	feedH *handler.FeedHandler,
) {
	app.Use(middleware.RequestID())
	app.Use(middleware.Logger())
	app.Use(middleware.Recovery())

	app.GET("/healthz", Healthz)
	app.HEAD("/healthz", Healthz)

	v1 := app.Group("/v1")

	{
		usersGroup := v1.Group("/users", authMW(model.UserRoleAdmin))
		{
			usersGroup.POST("/", userH.Create)
			usersGroup.GET("/", userH.List)
			usersGroup.GET("/:id", userH.GetByID)
			usersGroup.PUT("/:id", userH.Update)
			usersGroup.DELETE("/:id", userH.Delete)
		}
		// Outside the admin group: every user can search the others.
		v1.GET("/users/search", middleware.RateLimiter(time.Minute, 30), authMW(), friendshipH.SearchUsers)

		authGroup := v1.Group("/auth")
		{
			authGroup.POST("/register", middleware.RateLimiter(time.Minute, 5), authH.Register)
			authGroup.POST("/login", middleware.RateLimiter(time.Minute, 10), authH.Login)
			authGroup.DELETE("/logout", middleware.RateLimiter(time.Minute, 10), authMW(), authH.Logout)
			authGroup.PUT("/refresh", middleware.RateLimiter(time.Minute, 10), authH.RefreshToken)
		}

		videosGroup := v1.Group("/videos", middleware.RateLimiter(time.Minute, 10), authMW())
		{
			videosGroup.POST("/upload-url", videoH.GetUploadURL)
			videosGroup.PUT("/upload-done/:id", videoH.UploadComplete)
			videosGroup.GET("/download-url/:id", videoH.GetDownloadURL)
			videosGroup.GET("/", videoH.ListVideos)
			videosGroup.GET("/:id", videoH.GetVideo)
		}

		analysesGroup := v1.Group("/analysis", middleware.RateLimiter(time.Minute, 10), authMW())
		{
			analysesGroup.POST("/", analysisH.Create)
			analysesGroup.GET("", analysisH.List)
			analysesGroup.GET("/:id", analysisH.GetByID)
			analysesGroup.POST("/:id/retry-advice", analysisH.RetryAdvice)
		}

		profileGroup := v1.Group("/profile", middleware.RateLimiter(time.Minute, 10), authMW())
		{
			profileGroup.GET("", profileH.GetMyProfile)
			profileGroup.PUT("", profileH.UpdateMyProfile)
			profileGroup.GET("/constraints", bodyConstraintH.List)
			profileGroup.POST("/constraints", bodyConstraintH.Declare)
			profileGroup.DELETE("/constraints/:id", bodyConstraintH.Remove)
		}

		climbingSessionsGroup := v1.Group("/sessions", middleware.RateLimiter(time.Minute, 10), authMW())
		{
			climbingSessionsGroup.POST("", climbingSessionH.Create)
			climbingSessionsGroup.GET("", climbingSessionH.List)
			climbingSessionsGroup.GET("/active", climbingSessionH.GetActive)
			climbingSessionsGroup.GET("/:id", climbingSessionH.GetByID)
			climbingSessionsGroup.PUT("/:id", climbingSessionH.Update)
			climbingSessionsGroup.DELETE("/:id", climbingSessionH.Delete)
			climbingSessionsGroup.POST("/:id/analyses", climbingSessionH.AddAnalysis)
		}

		friendsGroup := v1.Group("/friends", middleware.RateLimiter(time.Minute, 10), authMW())
		{
			friendsGroup.GET("", friendshipH.ListFriends)
			friendsGroup.GET("/requests", friendshipH.ListRequests)
			friendsGroup.POST("/requests/:userId", friendshipH.SendRequest)
			friendsGroup.PUT("/requests/:id", friendshipH.AnswerRequest)
		}

		v1.GET("/feed", middleware.RateLimiter(time.Minute, 30), authMW(), feedH.Get)
	}
}

// Healthz is the liveness probe of the API. It answers 200 OK to GET and
// HEAD, so `curl -I` and the container healthchecks can use it.
func Healthz(c *gin.Context) {
	c.Status(http.StatusOK)
}
