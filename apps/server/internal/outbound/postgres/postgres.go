// @date 2026-09-09
// @file postgres.go
// @brief File description.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>, DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package postgres

import (
	"context"
	"embed"
	"errors"
	"fmt"
	"time"

	"github.com/golang-migrate/migrate/v4"
	_ "github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"
	"github.com/golang-migrate/migrate/v4/source/iofs"
	"github.com/jackc/pgx/v5/pgxpool"
)

type PostgresRepository struct {
	Pool *pgxpool.Pool
}

//go:embed migrations/*.sql
var migrationFS embed.FS

func New(dsn string) (PostgresRepository, error) {
	config, err := pgxpool.ParseConfig(dsn)
	if err != nil {
		return PostgresRepository{}, fmt.Errorf("open connection to %s: %w", dsn, err)
	}

	config.MaxConns = 25
	config.MinConns = 5
	config.MaxConnLifetime = time.Hour

	pool, err := pgxpool.NewWithConfig(context.Background(), config)
	if err != nil {
		return PostgresRepository{}, fmt.Errorf("create pool with config: %w", err)
	}

	if err := pool.Ping(context.Background()); err != nil {
		return PostgresRepository{}, fmt.Errorf("ping pool: %w", err)
	}

	return PostgresRepository{Pool: pool}, nil
}

func (r *PostgresRepository) Migrate(dsn string) error {
	source, err := iofs.New(migrationFS, "migrations")
	if err != nil {
		return fmt.Errorf("create iofs: %w", err)
	}

	m, err := migrate.NewWithSourceInstance(
		"iofs",
		source,
		dsn,
	)
	if err != nil {
		return fmt.Errorf("create migrator instance: %w", err)
	}

	if err := m.Up(); err != nil && !errors.Is(err, migrate.ErrNoChange) {
		return fmt.Errorf("load migration: %w", err)
	}

	return nil
}
