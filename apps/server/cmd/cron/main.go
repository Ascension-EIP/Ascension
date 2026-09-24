// @date 2026-09-20
// @file main.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package main

import (
	"context"
	"log/slog"
	"os"
	"os/signal"
	"syscall"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/job"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/outbound/minio"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/outbound/postgres"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/service"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/setup/config"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/setup/logger"
	"github.com/robfig/cron/v3"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		slog.Error("failed to load config", slog.String("err", err.Error()))
		os.Exit(1)
	}

	l := logger.New(cfg.Log.Level, cfg.Log.Pretty)
	slog.SetDefault(l)

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

	sessionS := service.NewSessionService(cfg.Auth.Session, &repo)
	videoS := service.NewVideoService(cfg.Video, cfg.MinIO, &storage, &repo)
	quotaUsageS := service.NewQuotaUsageService(&repo)

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	c := cron.New()
	if err := job.ClearExpiredSessions(c, ctx, &sessionS); err != nil {
		slog.Error("start the job: ClearExpiredSessions", slog.String("err", err.Error()))
		os.Exit(1)
	}
	if err := job.ClearUploadExpiredVideos(c, ctx, &videoS); err != nil {
		slog.Error("start the job: ClearUploadExpiredVideos", slog.String("err", err.Error()))
		os.Exit(1)
	}
	if err := job.ClearExpiredVideos(c, ctx, &videoS); err != nil {
		slog.Error("start the job: ClearExpiredVideos", slog.String("err", err.Error()))
		os.Exit(1)
	}
	if err := job.ClearOldQuotaUsage(c, ctx, &quotaUsageS); err != nil {
		slog.Error("start the job: ClearOldQuotaUsage", slog.String("err", err.Error()))
		os.Exit(1)
	}
	c.Start()

	<-ctx.Done()
	slog.Info("CTRL-C successfully handle")

	c.Stop().Done()
}
