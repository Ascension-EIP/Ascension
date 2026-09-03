// @date 2026-03-11
// @file main.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package main

import (
	"log"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/app"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/setup/config"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/setup/logger"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		log.Fatalln("config.Load:", err)
	}

	l := logger.New(cfg.Log.Level, cfg.Log.Pretty)

	app.Run(cfg, &l)
}
