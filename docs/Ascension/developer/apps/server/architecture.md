---
id: 8a400878-485e-480a-b6c4-a7bc4cd0e4be
---

:::success
**Version:** 1.2
:::

---

# Server Architecture

This document explains how the Ascension backend server is structured and why it is built that way. No prior Go or architecture knowledge is required to read this.

---

## Tech stack

| Technology | Role |
| --- | --- |
| **Go (1.27)** | Programming language |
| **Gin (1.12.0)** | HTTP web framework |
| **pgx/v5 (5.10.0)** | PostgreSQL driver & connection pool (`pgxpool`) |
| **Goroutines** | Concurrency handling |
| **PostgreSQL 18** | Relational database with JSONB document support |
| **RabbitMQ 4.x** | AMQP message broker for asynchronous job dispatching |
| **MinIO** | S3-compatible object storage for videos and frames |
| **robfig/cron/v3** | Cron scheduler for background cleanup tasks |
| **golang-migrate/v4** | Database schema migrations engine |
| **log/slog** | Standard library structured logger |
| **caarlos0/env/v11** | Type-safe environment configuration parser |

---

## What is Hexagonal Architecture?

Hexagonal architecture (also called **Ports & Adapters**) is a way of organizing code so that the core business logic is completely isolated from the outside world (HTTP, databases, message brokers, object storage).

```
┌────────────────────────────────────────────────────────┐
│                        OUTSIDE                         │
│                                                        │
│   HTTP Requests               PostgreSQL Database      │
│   (Inbound / Adapters)        (Outbound / Adapters)    │
│         │                               ▲              │
│         ▼                               │              │
│    ┌──────────────────────────────────────────────┐    │
│    │               DOMAIN (Core)                  │    │
│    │                                              │    │
│    │   Models (internal/model)                    │    │
│    │   Ports / Interfaces (internal/model/ports)  │    │
│    │   Services (internal/service)                │    │
│    │                                              │    │
│    │   Knows NOTHING about Gin or HTTP            │    │
│    │   Knows NOTHING about SQL queries            │    │
│    └──────────────────────────────────────────────┘    │
│         ▲                               │              │
│         │                               ▼              │
│   Cron Scheduler                 RabbitMQ / MinIO      │
│   (cmd/cron & internal/job)      (Outbound / Adapters) │
└────────────────────────────────────────────────────────┘
```

**The key rule:** the Domain never imports anything from Inbound or Outbound. It defines *what* it needs through **interfaces** (called "ports" in `internal/model/ports.go`). The Outbound layers (and Inbound callers) implement or consume those ports ("adapters").

**Why?**

- The core business logic is completely isolated and unit-testable without spinning up databases or HTTP servers.
- The domain layer defines interfaces for repositories, queues, and storages.
- The outbound and inbound layers implement these interfaces as concrete adapters.

---

## The layers of the server

### Domain (the core)

**Location:** `internal/model/` and `internal/service/`

This is the heart of the application:

- **Models** (`internal/model/`) – The data structures representing business entities (`User`, `Video`, `Analysis`, `Session`, `JWT`). Each model includes its domain validation logic (`Validate()`).
- **Ports** (`internal/model/ports.go`) – Go interfaces defining what the domain expects from infrastructure:
  - `UserRepository`: user persistence operations (Create, Get, List, Update, Delete).
  - `SessionRepository`: refresh token session persistence and revocation.
  - `VideoRepository`: video metadata persistence and expiration updates.
  - `AnalysisRepository`: analysis job tracking, progress, and result persistence.
  - `VideoStorage`: presigned URL generation and object storage management.
  - `AnalysisQueue`: publishing analysis jobs to RabbitMQ.
  - `TransactionManager`: atomic transactional execution boundaries.
- **Services** (`internal/service/`) – Concrete business logic implementations (`UserService`, `AuthService`, `VideoService`, `AnalysisService`, `JWTService`, `SessionService`). Services orchestrate workflows, validate constraints, hash passwords, and invoke ports.

---

### Inbound (HTTP layer)

**Location:** `internal/inbound/http/`

Responsible for:

1. **Listening** for incoming HTTP requests on a TCP port via Gin.
2. **Routing** requests to handlers (`internal/inbound/http/router/router.go`).
3. **Parsing & Validating** JSON bodies and parameters into DTO structs (`internal/inbound/http/dto/request/`).
4. **Enforcing Middlewares** (`internal/inbound/http/middleware/`): Request ID, Logger, Recovery, Rate Limiting, and JWT role-based Auth.
5. **Invoking** Domain services and formatting domain outputs into JSON responses (`internal/inbound/http/dto/response/`).

---

### Outbound (Infrastructure adapters)

**Location:** `internal/outbound/`

Implements the domain ports defined in `internal/model/ports.go`:

| Package | Role | Port Implemented |
| --- | --- | --- |
| `internal/outbound/postgres/` | PostgreSQL adapter using `pgxpool` | `UserRepository`, `SessionRepository`, `VideoRepository`, `AnalysisRepository`, `TransactionManager` |
| `internal/outbound/rabbitmq/` | RabbitMQ adapter using `amqp091-go` | `AnalysisQueue` |
| `internal/outbound/minio/` | S3-compatible adapter using `minio-go/v7` | `VideoStorage` |

---

### Scheduled Jobs (Cron layer)

**Location:** `internal/job/` and `cmd/cron/`

Background maintenance workers orchestrated via `robfig/cron/v3`:

- `ClearExpiredSessions`: Purges expired or revoked refresh sessions daily.
- `ClearUploadExpiredVideos`: Cleans up abandoned presigned video uploads hourly.
- `ClearExpiredVideos`: Purges completed videos that have passed retention and were not marked `retained`.

---

## Step-by-step Request Flow Example (`POST /v1/auth/signup`)

```
Client
  │
  │  POST /v1/auth/signup  { "username": "...", "email": "...", "password": "...", "first_name": "...", "last_name": "..." }
  ▼
Gin Router  (internal/inbound/http/router/router.go)
  │  Matches route, applies RateLimiter(1m, 5)
  ▼
Handler: AuthHandler.SignupLogin()  (internal/inbound/http/handler/auth.go)
  │  1. Binds JSON body → request.SignupLoginForm
  │  2. Converts DTO to model.SignupForm
  ▼
Service: AuthService.SignupLogin()  (internal/service/auth.go)
  │  1. Invokes UserService.CreateUser() → hashes password with bcrypt
  │  2. Calls UserRepository.CreateUser() (via port)
  │  3. Issues JWT access token via JWTService
  │  4. Creates refresh session via SessionService
  ▼
Repository: PostgresRepository.CreateUser()  (internal/outbound/postgres/user.go)
  │  Executes INSERT INTO users ... using pgxpool
  ▼
Handler
  │  Maps domain models → response.LoginResponse
  │  Serializes DTO to JSON and returns HTTP 200 OK
  ▼
Client
```

---

## File structure map

```
apps/server/
├── cmd/
│   ├── server/
│   │   └── main.go                     # API HTTP server entry point
│   ├── cron/
│   │   └── main.go                     # Background cron runner entry point
│   └── migrate/
│       └── main.go                     # Database migration CLI tool
├── go.mod                              # Go module definition (Go 1.27)
├── go.sum                              # Go dependency checksums
├── Dockerfile                          # Multi-stage production container build
├── moon.yml                            # moon monorepo task configuration
├── migrations/                         # SQL migration files (.up.sql / .down.sql)
└── internal/
    ├── app/
    │   └── app.go                      # Dependency injection and server lifecycle
    ├── job/                            # Background cron jobs (sessions, videos)
    │   ├── clear_expired_session.go
    │   ├── clear_expired_video.go
    │   └── clear_upload_expired_video.go
    ├── model/                          # Domain entities, validation rules, and ports
    │   ├── analysis.go
    │   ├── auth.go
    │   ├── error.go
    │   ├── jwt.go
    │   ├── ports.go                    # Central domain port interfaces
    │   ├── session.go
    │   ├── user.go
    │   └── video.go
    ├── service/                        # Domain services (business logic)
    │   ├── analysis.go
    │   ├── auth.go
    │   ├── jwt.go
    │   ├── session.go
    │   ├── user.go
    │   └── video.go
    ├── inbound/                        # HTTP controllers / adapters
    │   └── http/
    │       ├── dto/
    │       │   ├── request/            # Request binding structs & validation
    │       │   └── response/           # Output response structs
    │       ├── handler/                # Gin router handlers (controllers)
    │       ├── macro/                  # Context and parameter key constants
    │       ├── middleware/             # Gin middlewares (auth, logger, rate_limit, recovery, request_id)
    │       ├── router/                 # Router configuration and route groups
    │       └── utils/                  # Context helpers and standardized error formatting
    ├── outbound/                       # Infrastructure adapters
    │   ├── postgres/                   # PostgreSQL storage repository (pgx implementation)
    │   ├── rabbitmq/                   # RabbitMQ message broker adapter
    │   └── minio/                      # MinIO / S3 object storage adapter
    └── setup/
        ├── config/                     # Environment configuration loader
        └── logger/                     # Structured logger constructor (slog)
```

---

## Entry Points

1. **API Server (`cmd/server/main.go`)**:
   - Parses configuration via `config.Load()`.
   - Initializes structured logging with `slog`.
   - Calls `app.Run(cfg)` which establishes database pools, runs pending migrations via `repo.Migrate()`, initializes storage and RabbitMQ, wires services and handlers, and starts the Gin HTTP server with graceful shutdown handling.

2. **Cron Worker (`cmd/cron/main.go`)**:
   - Bootstraps dependencies and starts `robfig/cron` to execute periodic database and storage cleanup tasks independently of HTTP traffic.

Database schema migrations are applied automatically at server startup or on demand via `moon run server:migrate` using the official `golang-migrate` CLI.

---

## Configuration

The server parses all environment variables through `internal/setup/config/config.go` with domain-specific prefixes:

- `POSTGRES_*` : Database host, port, database name (`POSTGRES_DB`), user, password, and SSL parameters.
- `MINIO_*` : Object storage endpoint, credentials, bucket name, and URL expiration durations.
- `RABBITMQ_*` : Message broker host, port, user, password, TLS, and queue names.
- `AUTH_*` : JWT and session secret keys and expiration durations.
- `PORT` & `HTTPS` : HTTP server listener configuration.
- `LOG_LEVEL` & `LOG_PRETTY` : Logging verbosity and formatting.
