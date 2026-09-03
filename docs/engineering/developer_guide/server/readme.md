---
id: 92f57290-3136-4d94-8403-1c0041aa21d2
---

> **Last updated:** 12th March 2026
> **Version:** 1.1
> **Authors:** Nicolas
> **Status:** Done
> {.is-success}

---

# Server — Developer Guide

This guide covers everything a new developer needs to start working on the Ascension backend server. It complements the [architecture overview](./architecture.md) and the [API routes reference](./api-routes.md) and the [Swagger UI guide](./swagger.md).

---

## Table of Contents

- [Server — Developer Guide](#server--developer-guide)

  - [Table of Contents](#table-of-contents)

  - [Prerequisites](#prerequisites)

  - [Tech Stack](#tech-stack)

  - [Repository Layout](#repository-layout)

  - [Environment Variables](#environment-variables)

  - [Running Locally](#running-locally)

    - [1\. Start the infrastructure](#1-start-the-infrastructure)

    - [2\. Install sqlx-cli](#2-install-sqlx-cli)

    - [3\. Run database migrations](#3-run-database-migrations)

    - [4\. Start the server](#4-start-the-server)

  - [Moon Tasks Reference](#moon-tasks-reference)

  - [Database Migrations](#database-migrations)

  - [SQLx Offline Mode](#sqlx-offline-mode)

  - [Testing](#testing)

  - [Docker](#docker)

  - [Common Errors](#common-errors)


---

## Prerequisites

- **Go** (toolchain version `1.25.5` — download from go.dev or use proto)

- **Docker** + **Docker Compose** — for PostgreSQL, RabbitMQ, MinIO locally

- **moon** — monorepo task runner (see [Developer Quickstart](../README.md))


---

## Tech Stack

| Technology | Version | Role |
| --- | --- | --- |
| **Go** | 1.25.5 | Language |
| **Gin** | 1.12.0 | HTTP web framework |
| **pgx/v5** | 5.8.0 | Async PostgreSQL driver & connection pool |
| **PostgreSQL** | 18 | Relational database |
| **RabbitMQ** | 4.x | Message broker (dispatches AI jobs) |
| **MinIO** | RELEASE.2025-09-07 | S3-compatible object storage for videos |
| **golang-jwt** | 5.3.1 | JWT creation and validation |
| **golang.org/x/time** | \- | Rate limiting |

---

## Repository Layout

```
apps/server/
├── go.mod              # Go module definition
├── go.sum              # Go dependencies checksums
├── migrations/         # SQL migration files, applied in timestamp order
├── moon.yml            # moon task definitions
├── cmd/
│   └── server/
│       └── main.go     # Entry point — wires all layers together
└── internal/
    ├── app/            # App lifecycle and main runners
    ├── inbound/        # HTTP layer — Gin router, handlers, middleware
    ├── outbound/       # Database & external adapters — pgx, rabbitmq, minio
    ├── service/        # Business logic services
    ├── model/          # Domain models (user, video, analysis)
    └── setup/          # Configuration and logger setup
```

For a deeper explanation of each layer, read the [architecture overview](./architecture.md).

---

## Environment Variables

Copy `.env.example` to `.env` at the repository root and fill in the values. The server reads all of these at startup via `internal/setup/config/config.go`.

| Variable | Required | Default | Description |
| --- | --- | --- | --- |
| `DB_HOST` | ❌ | `localhost` | PostgreSQL host |
| `DB_PORT` | ❌ | `5432` | PostgreSQL port |
| `DB_NAME` | ✅ | — | PostgreSQL database name |
| `DB_USER` | ✅ | — | PostgreSQL user |
| `DB_PASS` | ✅ | — | PostgreSQL password |
| `DB_MIGRATION` | ❌ | — | Directory to run migrations from (e.g. `file://migrations`) |
| `LOG_LEVEL` | ❌ | `info` | Logging verbosity |

---

## Running Locally

### 1\. Start the infrastructure

```bash
# From the repository root
docker compose up -d
```

This starts PostgreSQL (port 5432), RabbitMQ (port 5672 / 15672), and MinIO (port 9000 / 9001).

### 2\. Run database migrations

Migrations can be run automatically by the Go server on startup if you set the `DB_MIGRATION` environment variable pointing to the `migrations` directory (e.g., `file://migrations`).

### 3\. Start the Go server

```bash
moon run server:dev
```

The server will start on port `8080` by default. Reloading on code changes is **not** automatic — restart manually after changes.

To run Go directly:

```bash
go run ./cmd/server
```

---

## Moon Tasks Reference

Run these from the repository root with `moon run server:<task>`.

| Task | Command | Description |
| --- | --- | --- |
| `install` | `go mod download` | Resolves and downloads Go dependencies |
| `dev` | `go run ./cmd/server` | Starts the server with `LOG_LEVEL=debug` |
| `build` | `go build ...` | Debug build of the server |
| `build-release` | `go build -ldflags ...` | Release build (runs lint first) |
| `lint` | `go vet ./...` | Standard compiler static checks |
| `format` | `go fmt ./...` | Auto-format Go files |
| `test` | `go test ./...` | Run Go unit and integration tests |

---

## Database Migrations

Migrations live in `apps/server/migrations/` and are named with a UTC timestamp prefix:

```
20260303132858_create_users_table.sql
20260307000001_create_videos_table.sql
20260307000002_create_analyses_table.sql
```

**Rules:**

- Never edit a migration file that has already been applied — create a new one instead.

- The `set_updated_at` trigger function (created in `create_users_table.sql`) is reusable in any migration.


---

## Testing

Tests live under `internal/service/` or `internal/outbound/postgres/` depending on the layer being tested.

```bash
moon run server:test
# or
go test ./...
```

---

## Docker

The server has a `Dockerfile` at `apps/server/Dockerfile`.

**Multi-stage build:**

1. `go-builder` — compiles the Go binary using Alpine Go image.

2. `runtime` — copies the binary and migrations into a lightweight Alpine image.


```bash
# Build the image locally
docker build -t ascension-server apps/server/

# Run it
docker run --env-file .env -p 8080:8080 ascension-server
```

**In production**, use:

```bash
docker compose --profile prod up -d
```

This starts the server alongside PostgreSQL, RabbitMQ, MinIO, and the AI worker. The server image is pulled from the GitHub Container Registry (`ghcr.io/ascension-eip/ascension-server`).

---

## Common Errors

| Error | Likely cause | Fix |
| --- | --- | --- |
| `required DB parameters missing` | `.env` not loaded or missing variables | Copy `.env.example` to `.env` and fill variables |
| `Connection refused (os error 111)` on port 5432 | PostgreSQL not running | `docker compose up -d` |