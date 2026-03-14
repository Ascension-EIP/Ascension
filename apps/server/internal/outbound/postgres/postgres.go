package postgres

import (
	"context"
	"fmt"
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
		if err := migrateDB(dsn, migrationDir); err != nil {
			return PostgresRepository{}, err
		}
		l.Info().Msg("migration completed successfully")
	}

	return PostgresRepository{Pool: pool}, nil
}

func migrateDB(dsn string, migrationDir string) error {
	m, err := migrate.New(
		migrationDir,
		dsn,
	)
	if err != nil {
		return fmt.Errorf("cannot create migrate instance: %v", err)
	}

	if err := m.Up(); err != nil && err != migrate.ErrNoChange {
		return fmt.Errorf("cannot migrate: %v", err)
	}

	return nil
}
