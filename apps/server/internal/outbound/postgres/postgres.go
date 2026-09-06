// @date 2026-09-06
// @file postgres.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>, Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package postgres

import (
	"context"
	"fmt"
	"os"
	"strings"
	"time"

	"github.com/golang-migrate/migrate/v4"
	_ "github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/rs/zerolog"
)

type PostgresRepository struct {
	Pool *pgxpool.Pool
	l    *zerolog.Logger
}

func New(l *zerolog.Logger, dsn string, migrationDir string) (PostgresRepository, error) {
	config, err := pgxpool.ParseConfig(dsn)
	if err != nil {
		return PostgresRepository{}, err
	}

	config.MaxConns = 25
	config.MinConns = 5
	config.MaxConnLifetime = time.Hour

	pool, err := pgxpool.NewWithConfig(context.Background(), config)
	if err != nil {
		return PostgresRepository{}, err
	}

	if err := pool.Ping(context.Background()); err != nil {
		return PostgresRepository{}, err
	}

	if migrationDir != "" {
		if err := MigrateDB(dsn, migrationDir); err != nil {
			return PostgresRepository{}, err
		}
		l.Info().Msg("migration completed successfully")
	}

	return PostgresRepository{Pool: pool}, nil
}

func ResolveMigrationDir(migrationDir string) string {
	clean := strings.TrimPrefix(migrationDir, "file://")
	clean = strings.TrimPrefix(clean, "folder://")
	clean = strings.TrimPrefix(clean, "dir://")
	if clean == "" || clean == "true" || clean == "1" {
		if _, err := os.Stat("migrations"); err == nil {
			return "migrations"
		}
		if _, err := os.Stat("apps/server/migrations"); err == nil {
			return "apps/server/migrations"
		}
		return "migrations"
	}
	return clean
}

func MigrateDB(dsn string, migrationDir string) error {
	dirPath := ResolveMigrationDir(migrationDir)
	src, err := NewDirSource(dirPath)
	if err != nil {
		return fmt.Errorf("cannot create migration source: %w", err)
	}

	m, err := migrate.NewWithSourceInstance(
		"folder",
		src,
		dsn,
	)
	if err != nil {
		return fmt.Errorf("cannot create migrate instance: %w", err)
	}
	defer m.Close()

	if err := m.Up(); err != nil && err != migrate.ErrNoChange {
		return fmt.Errorf("cannot migrate: %w", err)
	}

	return nil
}
