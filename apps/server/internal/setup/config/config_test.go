package config

import (
	"testing"
	"time"

	"github.com/caarlos0/env/v11"
	"github.com/stretchr/testify/require"
)

func TestConfigLoadWithRequired(t *testing.T) {
	t.Setenv("DB_USER", "user")
	t.Setenv("DB_PASS", "password")
	t.Setenv("DB_NAME", "db")
	got, err := Load()
	require.NoError(t, err)
	want := &Config{
		DB: DBConfig{
			Host:      "localhost",
			Port:      5432,
			Name:      "db",
			User:      "user",
			Password:  "password",
			Params:    "sslmode=disable",
			Migration: "file://db/migrations",
		},
		Auth: AuthConfig{
			CookieExp:  24 * time.Hour,
			CookieName: "user_session",
		},
		HTTP: HTTPConfig{
			Port:  8080,
			HTTPS: false,
		},
		Log: LogConfig{
			Pretty: false,
			Level:  "info",
		},
	}
	require.Equal(t, got, want)
}

func TestConfigLoadWithoutRequired(t *testing.T) {
	t.Setenv("DB_PASS", "password")
	t.Setenv("DB_NAME", "db")
	_, err := Load()
	require.ErrorIs(t, err, env.VarIsNotSetError{Key: "user"})
}

func TestConfigDSN(t *testing.T) {
	cfg := DBConfig{
		Host:     "localhost",
		Port:     5432,
		Name:     "db",
		User:     "user",
		Password: "password",
		Params:   "sslmode=disable",
	}
	got := cfg.DSN()
	want := "postgres://user:password@localhost:5432/db?sslmode=disable"
	require.Equal(t, got, want)
}
