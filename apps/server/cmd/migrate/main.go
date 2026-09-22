// @date 2026-09-21
// @file main.go
// @brief CLI tool to execute PostgreSQL migrations.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package main

import (
	"log/slog"
	"os"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/outbound/postgres"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/setup/config"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/setup/logger"
	"github.com/caarlos0/env/v11"
)

type migrateConfig struct {
	DB  config.DBConfig  `envPrefix:"POSTGRES_"`
	Log config.LogConfig `envPrefix:"LOG_"`
}

func main() {
	var cfg migrateConfig
	if err := env.Parse(&cfg); err != nil {
		slog.Error("failed to load database config", slog.String("err", err.Error()))
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
	}

	slog.Info("migration completed successfully")
}
