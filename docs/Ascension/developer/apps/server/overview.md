---
id: 2f835188-7fa7-46eb-84ab-0f2bcdda5321
---

:::success
**Version:** 1.2
:::

---

# Server — Developer Guide

This guide covers everything a new developer needs to start working on the Ascension backend server. It complements the [architecture overview](architecture.md), the [API routes reference](api-routes.md), and the [Swagger UI guide](swagger.md).

---

## Prerequisites

- **Go** (toolchain version `1.27` — download from go.dev or use your package manager)
- **Docker** + **Docker Compose** — for PostgreSQL, RabbitMQ, and MinIO locally
- **moon** — monorepo task runner (see [monorepo-guide](../../architecture/monorepo-guide.md))

---

## Tech Stack

| Technology | Version | Role |
| --- | --- | --- |
| **Go** | 1.27 | Primary programming language |
| **Gin** | 1.12.0 | HTTP web framework |
| **pgx/v5** | 5.10.0 | Async PostgreSQL driver & connection pool |
| **PostgreSQL** | 18 | Relational database (with JSONB telemetry) |
| **RabbitMQ** | 4.3.5 / 4.x | Message broker (amqp091-go driver) |
| **MinIO** | RELEASE.2025-09-07 | S3-compatible object storage for videos |
| **golang-jwt** | 5.3.1 | JWT creation and validation |
| **golang-migrate** | 4.19.1 | Database migrations engine |
| **caarlos0/env** | 11.4.1 | Type-safe environment configuration parser |
| **robfig/cron** | 3.0.1 | Scheduled background maintenance jobs |
| **log/slog** | Go stdlib | Structured JSON / text logging |
| **golang.org/x/time** | 0.15.0 | Per-route rate limiting |

---

## Repository Layout

```
apps/server/
├── go.mod              # Go module definition (Go 1.27)
├── go.sum              # Go dependencies checksums
├── Dockerfile          # Multi-stage production container build
├── moon.yml            # moon task definitions
├── bin/                # Compiled binary outputs (server, cron, migrate)
├── migrations/         # SQL migration files (.up.sql / .down.sql pairs)
├── cmd/
│   ├── server/
│   │   └── main.go     # API Server HTTP entry point
│   ├── cron/
│   │   └── main.go     # Background cron worker (session & video cleanup)
│   └── migrate/
│       └── main.go     # Standalone CLI tool to execute DB migrations
└── internal/
    ├── app/            # App lifecycle, DI wiring, and graceful shutdown
    ├── inbound/        # HTTP layer — Gin router, handlers, DTOs, middlewares
    ├── job/            # Scheduled job definitions (expired sessions/videos)
    ├── model/          # Domain entities, validation rules, and repository ports
    ├── outbound/       # Infrastructure adapters — pgx, rabbitmq, minio
    ├── service/        # Domain business logic (analysis, auth, jwt, user, video)
    └── setup/          # Configuration loading (env) and structured logger (slog)
```

For a deeper explanation of each layer, read the [architecture overview](architecture.md).

---

## Environment Variables

Copy `.env.example` to `.env` at the repository root and fill in the values. The server parses configuration with `caarlos0/env` at startup via `internal/setup/config/config.go`.

### Database (`POSTGRES_*`)

| Variable | Required | Default | Description |
| --- | --- | --- | --- |
| `POSTGRES_HOST` | ❌ | `localhost` | PostgreSQL host |
| `POSTGRES_PORT` | ❌ | `5432` | PostgreSQL port |
| `POSTGRES_DB` | ✅ | — | PostgreSQL database name |
| `POSTGRES_USER` | ✅ | — | PostgreSQL database user |
| `POSTGRES_PASSWORD` | ✅ | — | PostgreSQL database password |
| `POSTGRES_PARAMS` | ❌ | `sslmode=disable` | Connection query parameters |

### Storage (`MINIO_*`)

| Variable | Required | Default | Description |
| --- | --- | --- | --- |
| `MINIO_ENDPOINT` | ✅ | — | Object storage URL (e.g. `http://localhost:9000`) |
| `MINIO_ID` | ✅ | — | Access key / Root user |
| `MINIO_SECRET` | ✅ | — | Secret key / Root password |
| `MINIO_BUCKET` | ✅ | — | Target bucket for video uploads |
| `MINIO_SSL` | ❌ | `false` | Enable TLS/SSL |
| `MINIO_UPLOAD_EXP` | ❌ | `1h` | Presigned PUT URL validity duration |
| `MINIO_DOWNLAOD_EXP` | ❌ | `1h` | Presigned GET URL validity duration |

### Message Broker (`RABBITMQ_*`)

| Variable | Required | Default | Description |
| --- | --- | --- | --- |
| `RABBITMQ_HOST` | ❌ | `localhost` | RabbitMQ host |
| `RABBITMQ_PORT` | ❌ | `5672` | RabbitMQ AMQP port |
| `RABBITMQ_USER` | ✅ | — | RabbitMQ username |
| `RABBITMQ_PASS` | ✅ | — | RabbitMQ password |
| `RABBITMQ_TLS` | ❌ | `false` | Enable TLS connection |
| `RABBITMQ_QUEUE_AI` | ❌ | `vision.skeleton` | Target queue dispatched to AI workers |
| `RABBITMQ_QUEUE_SERVER` | ❌ | `ascension.events` | Incoming events exchange / queue |

### Auth & Tokens (`AUTH_*`)

| Variable | Required | Default | Description |
| --- | --- | --- | --- |
| `AUTH_JWT_EXP` | ❌ | `15m` | JWT access token expiration duration |
| `AUTH_JWT_SECRET` | ❌ | `jwt_secret` | Secret key used to sign JWTs |
| `AUTH_SESSION_EXP` | ❌ | `168h` (7d) | Refresh token session expiration |
| `AUTH_SESSION_REMEMBER_EXP` | ❌ | `720h` (30d) | Extended session duration when "Remember Me" is true |
| `AUTH_SESSION_SECRET` | ❌ | `session_secret` | Secret key for session cookie/token derivation |

### Server & Logging

| Variable | Required | Default | Description |
| --- | --- | --- | --- |
| `PORT` | ❌ | `8080` | HTTP listening port |
| `HTTPS` | ❌ | `false` | Enable HTTPS mode |
| `VIDEO_RETENTION` | ❌ | `8760h` (1 year) | Default retention duration for saved videos |
| `LOG_LEVEL` | ❌ | `info` | Log level (`debug`, `info`, `warn`, `error`) |
| `LOG_PRETTY` | ❌ | `false` | Format logs as human-readable text instead of JSON |

---

## Running Locally

### 1\. Start the infrastructure

```bash
# From the repository root
docker compose up -d
```

This starts PostgreSQL (port 5432), RabbitMQ (ports 5672 & 15672), and MinIO (ports 9000 & 9001).

### 2\. Run database migrations

Database migrations are executed automatically on server startup via `repo.Migrate()`. You can also run them manually using `golang-migrate` via Moon (after installing the CLI once via `moon run server:setup`):

```bash
# Install the official migrate CLI (first time)
moon run server:setup

# Run pending migrations
moon run server:migrate
```

### 3\. Start the Go server

```bash
moon run server:dev
```

The server will start on port `8080` by default.

To run Go directly:

```bash
go run ./cmd/server
```

To run the background cron worker:

```bash
go run ./cmd/cron
```

---

## Moon Tasks Reference

Run these from the repository root with `moon run server:<task>`.

| Task | Command | Description |
| --- | --- | --- |
| `install` | `go mod download` | Resolves and downloads Go dependencies |
| `setup` | `go install -tags postgres ...` | Installs the official `golang-migrate` CLI tool |
| `update` | `go get -u ./... && go mod tidy` | Updates dependencies and tidies `go.mod` |
| `migrate` | `migrate ... up` | Runs all pending database migrations |
| `dev` | `go run ./cmd/server` | Starts the server with `LOG_LEVEL=debug` |
| `build` | `go build -o bin/server ./cmd/server` | Compiles the server binary into `bin/server` |
| `lint` | `go vet ./...` | Standard compiler static checks |
| `format` | `go fmt ./...` | Auto-formats Go files |
| `test` | `go test ./...` | Runs Go unit and integration tests |
| `clean` | `rm -rf bin` | Cleans up the compiled binaries directory |

---

## Database Migrations

Migrations live in `apps/server/migrations/` (and are mirrored in `internal/outbound/postgres/migrations/`). Each migration consists of an up and down script with a timestamp prefix:

```
20260918172358_create_updated_at_trigger.up.sql
20260918172358_create_updated_at_trigger.down.sql
20260918172411_create_users_table.up.sql
20260918172411_create_users_table.down.sql
...
```

**Rules:**

- Always create both `.up.sql` and `.down.sql` files.
- Never edit an existing migration file that has already been merged or applied.
- The shared trigger `update_updated_at_column()` is created in the first migration and attached to all tables containing `updated_at`.

---

## Testing

Unit and integration tests live alongside their packages (e.g. `internal/model/user_test.go`):

```bash
moon run server:test
# or
go test ./...
```

---

## Docker

The server provides a multi-stage `Dockerfile` at `apps/server/Dockerfile`:

1. `go-builder` (`golang:1.27-alpine`) — compiles the static binary.
2. `runtime` (`alpine:3.24`) — unprivileged execution (`USER bob`) with migrations bundled.

```bash
# Build the image locally
docker build -t ascension-server apps/server/

# Run it
docker run --env-file .env -p 8080:8080 ascension-server
```

**In production / docker-compose**:

```bash
docker compose --profile prod up -d
```

---

## Common Errors

| Error | Likely cause | Fix |
| --- | --- | --- |
| `failed to load config: env: required environment variable ...` | Missing required environment variables | Ensure `.env` is loaded with all required variables defined |
| `Connection refused` on port 5432 | PostgreSQL not running | `docker compose up -d postgresql` |
| `Connection refused` on port 5672 | RabbitMQ not running | `docker compose up -d rabbitmq` |
