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
