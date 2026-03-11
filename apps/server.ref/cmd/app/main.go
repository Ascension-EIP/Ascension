package main

import (
	"log"

	"github.com/DimitriLaPoudre/go-backend-base/internal/app"
	"github.com/DimitriLaPoudre/go-backend-base/internal/infra/config"
	"github.com/DimitriLaPoudre/go-backend-base/pkg/logger"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		log.Fatalln("config.Load:", err)
	}

	l := logger.New(cfg.Log.Level, cfg.Log.Pretty)

	app.Run(cfg, l)
}
