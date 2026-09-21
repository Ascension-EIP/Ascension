// @date 2026-09-09
// @file main.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package main

import (
	"log/slog"
	"os"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/app"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/setup/config"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/setup/logger"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		slog.Error("failed to load config", slog.String("err", err.Error()))
		os.Exit(1)
	}

	l := logger.New(cfg.Log.Level, cfg.Log.Pretty)
	slog.SetDefault(l)

	app.Run(cfg)
}
