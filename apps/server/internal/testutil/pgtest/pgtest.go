// @date 2026-11-13
// @file pgtest.go
// @brief PostgreSQL integration test helpers: one migrated, throwaway database per test.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>, Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done Package pgtest gives integration tests a real PostgreSQL database. Tests are skipped unless TEST_DATABASE_DSN points at a PostgreSQL 18 server, for instance a throwaway container: docker run --rm -d --name ascension-test-pg -e POSTGRES_USER=test -e POSTGRES_PASSWORD=test -p 127.0.0.1:55432:5432 postgres:18 TEST_DATABASE_DSN='postgres://test:test@127.0.0.1:55432/postgres?sslmode=disable' go test ./... Each Open creates a new database on that server, applies every migration and drops the database when the test ends, so tests and packages never share data.
package pgtest

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"net/url"
	"os"
	"testing"

	"uuid"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/outbound/postgres"
	"github.com/jackc/pgx/v5"
)

// EnvDSN names the environment variable holding the PostgreSQL server DSN.
const EnvDSN = "TEST_DATABASE_DSN"

// DB is a migrated database dedicated to one test.
type DB struct {
	Repo *postgres.PostgresRepository
	DSN  string
}

// Open creates, migrates and returns a database dedicated to the test, or skips the
// test when TEST_DATABASE_DSN is not set.
func Open(t *testing.T) DB {
	t.Helper()

	serverDSN := os.Getenv(EnvDSN)
	if serverDSN == "" {
		t.Skipf("%s is not set: skipping the PostgreSQL integration test", EnvDSN)
	}

	ctx := context.Background()
	name := "ascension_test_" + randomSuffix(t)

	admin, err := pgx.Connect(ctx, serverDSN)
	if err != nil {
		t.Fatalf("connect to %s: %v", EnvDSN, err)
	}
	defer admin.Close(ctx)

	if _, err := admin.Exec(ctx, "CREATE DATABASE "+pgx.Identifier{name}.Sanitize()); err != nil {
		t.Fatalf("create database %s: %v", name, err)
	}
	t.Cleanup(func() {
		conn, err := pgx.Connect(context.Background(), serverDSN)
		if err != nil {
			t.Errorf("connect to drop database %s: %v", name, err)
			return
		}
		defer conn.Close(context.Background())
		if _, err := conn.Exec(context.Background(), "DROP DATABASE "+pgx.Identifier{name}.Sanitize()+" WITH (FORCE)"); err != nil {
			t.Errorf("drop database %s: %v", name, err)
		}
	})

	dsn, err := withDatabase(serverDSN, name)
	if err != nil {
		t.Fatalf("build the test database DSN: %v", err)
	}

	repo, err := postgres.New(dsn)
	if err != nil {
		t.Fatalf("open %s: %v", name, err)
	}
	t.Cleanup(repo.Pool.Close)

	if err := repo.Migrate(dsn); err != nil {
		t.Fatalf("migrate %s: %v", name, err)
	}

	return DB{Repo: &repo, DSN: dsn}
}

// CreateUser inserts a user and returns its ID.
func (db DB) CreateUser(t *testing.T) uuid.UUID {
	t.Helper()

	suffix := randomSuffix(t)
	var id uuid.UUID
	if err := db.Repo.Pool.QueryRow(context.Background(),
		"INSERT INTO users (username, first_name, last_name, email, password_hash) VALUES ($1, 'Test', 'Climber', $2, 'hash') RETURNING id",
		"climber_"+suffix, "climber_"+suffix+"@ascension.test",
	).Scan(&id); err != nil {
		t.Fatalf("insert user: %v", err)
	}

	return id
}

// CreateUserNamed inserts an active user with the username and returns its ID.
func (db DB) CreateUserNamed(t *testing.T, username string) uuid.UUID {
	t.Helper()

	var id uuid.UUID
	if err := db.Repo.Pool.QueryRow(context.Background(),
		"INSERT INTO users (username, first_name, last_name, email, password_hash) VALUES ($1, $2, $3, $4, 'hash') RETURNING id",
		username, "First "+username, "Last "+username, username+"@ascension.test",
	).Scan(&id); err != nil {
		t.Fatalf("insert user %s: %v", username, err)
	}

	return id
}

// DeactivateUser deactivates a user.
func (db DB) DeactivateUser(t *testing.T, id uuid.UUID) {
	t.Helper()

	if _, err := db.Repo.Pool.Exec(context.Background(),
		"UPDATE users SET status = 'deactivated', deactivated_at = NOW() WHERE id = $1", id,
	); err != nil {
		t.Fatalf("deactivate user: %v", err)
	}
}

// BlockPair stores a blocked friendship, replacing the one of the pair if any. No endpoint
// blocks a user yet: the tests set it directly.
func (db DB) BlockPair(t *testing.T, requesterID uuid.UUID, addresseeID uuid.UUID) {
	t.Helper()

	ctx := context.Background()
	if _, err := db.Repo.Pool.Exec(ctx,
		"DELETE FROM friendships WHERE LEAST(requester_id, addressee_id) = LEAST($1::uuid, $2::uuid) AND GREATEST(requester_id, addressee_id) = GREATEST($1::uuid, $2::uuid)",
		requesterID, addresseeID,
	); err != nil {
		t.Fatalf("delete friendship: %v", err)
	}
	if _, err := db.Repo.Pool.Exec(ctx,
		"INSERT INTO friendships (requester_id, addressee_id, status, responded_at) VALUES ($1, $2, 'blocked', NOW())",
		requesterID, addresseeID,
	); err != nil {
		t.Fatalf("insert blocked friendship: %v", err)
	}
}

// CreateVideo inserts a completed video of the user, optionally linked to a climbing session.
func (db DB) CreateVideo(t *testing.T, userID uuid.UUID, climbingSessionID *uuid.UUID) uuid.UUID {
	t.Helper()

	var id uuid.UUID
	if err := db.Repo.Pool.QueryRow(context.Background(),
		"INSERT INTO videos (user_id, object_key, climbing_session_id, status, content_type) VALUES ($1, $2, $3, 'completed', 'video/mp4') RETURNING id",
		userID, fmt.Sprintf("%s/%s.mp4", userID, randomSuffix(t)), climbingSessionID,
	).Scan(&id); err != nil {
		t.Fatalf("insert video: %v", err)
	}

	return id
}

func withDatabase(dsn string, name string) (string, error) {
	u, err := url.Parse(dsn)
	if err != nil {
		return "", err
	}
	u.Path = "/" + name

	return u.String(), nil
}

func randomSuffix(t *testing.T) string {
	t.Helper()

	b := make([]byte, 6)
	if _, err := rand.Read(b); err != nil {
		t.Fatalf("random suffix: %v", err)
	}

	return hex.EncodeToString(b)
}
