// @date 2026-09-05
// @file main.go
// @brief CLI tool to execute PostgreSQL migrations.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package main

import (
	"log"
	"os"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/outbound/postgres"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/setup/config"
	"github.com/caarlos0/env/v11"
	"github.com/rs/zerolog"
)

type migrateConfig struct {
	DB config.DBConfig `envPrefix:"POSTGRES_"`
}

func main() {
	l := zerolog.New(zerolog.ConsoleWriter{Out: os.Stdout}).With().Timestamp().Logger()

	cfg := migrateConfig{
		DB: config.DBConfig{
			Host:      "localhost",
			Port:      5432,
			Name:      "ascension",
			User:      "ascension",
			Password:  "ascension",
			Params:    "sslmode=disable",
			Migration: "true",
		},
	}

	if err := env.Parse(&cfg); err != nil {
		log.Fatalf("failed to parse environment variables: %v", err)
	}

	dsn := cfg.DB.DSN()
	l.Info().
		Str("host", cfg.DB.Host).
		Int("port", cfg.DB.Port).
		Str("database", cfg.DB.Name).
		Msg("applying database migrations...")

	if err := postgres.MigrateDB(dsn, cfg.DB.Migration); err != nil {
		l.Fatal().Err(err).Msg("database migration failed")
	}

	l.Info().Msg("database migrations applied successfully")
}
