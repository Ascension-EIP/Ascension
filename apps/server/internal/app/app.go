// @date 2026-09-20
// @file app.go
// @brief File description.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>, DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package app

import (
	"context"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/inbound/http/handler"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/inbound/http/middleware"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/inbound/http/router"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/outbound/minio"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/outbound/postgres"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/outbound/rabbitmq"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/service"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/setup/config"
	"github.com/gin-gonic/gin"
)

func Run(cfg config.Config) {
	repo, err := postgres.New(cfg.DB.DSN())
	if err != nil {
		slog.Error("failed to create a new postgres repository", slog.String("err", err.Error()))
		os.Exit(1)
	}
	if err := repo.Migrate(cfg.DB.DSN()); err != nil {
		slog.Error("failed to migrate the database", slog.String("err", err.Error()))
		os.Exit(1)
	} else {
		slog.Info("migration completed successfully")
	}

	storage, err := minio.New(cfg.MinIO)
	if err != nil {
		slog.Error("failed to create a new minio storage", slog.String("err", err.Error()))
		os.Exit(1)
	}
	queue, err := rabbitmq.New(cfg.RabbitMQ)
	if err != nil {
		slog.Error("failed to create a new rabbitmq queue", slog.String("err", err.Error()))
		os.Exit(1)
	}

	jwtS := service.NewJWTService(cfg.Auth.JWT)
	sessionS := service.NewSessionService(cfg.Auth.Session, &repo)
	userS := service.NewUserService(&repo)
	userProfileS := service.NewUserProfileService(&repo)
	authS := service.NewAuthService(&jwtS, &sessionS, &userS, &userProfileS, &repo)
	videoS := service.NewVideoService(cfg.Video, cfg.MinIO, &storage, &repo)
	analysisS := service.NewAnalysisService(cfg.MinIO, &repo, &repo, &queue)

	authMW := middleware.AuthMiddleware(&jwtS)

	userH := handler.NewUserHandler(&userS)
	authH := handler.NewAuthHandler(&authS)
	videoH := handler.NewVideoHandler(&videoS)
	analysisH := handler.NewAnalysisHandler(&analysisS)
	userProfileH := handler.NewUserProfileHandler(&userProfileS)

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	app := gin.New()
	router.New(app, cfg,
		authMW,

		&userH,
		&authH,
		&videoH,
		&analysisH,
		&userProfileH,
	)
	httpServ := &http.Server{
		Addr:    ":" + strconv.Itoa(cfg.HTTP.Port),
		Handler: app,
	}
	go func() {
		slog.Info("server starting on " + httpServ.Addr)
		if err := httpServ.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			slog.Error("failed to start server", slog.String("err", err.Error()))
		}
	}()

	<-ctx.Done()
	slog.Info("CTRL-C successfully handle")

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()
	if err := httpServ.Shutdown(ctx); err != nil {
		slog.Error("server forced to shutdown", slog.String("err", err.Error()))
	}
}
