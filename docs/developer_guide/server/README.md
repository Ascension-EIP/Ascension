> **Last updated:** 9th March 2026  
> **Version:** 1.0  
> **Authors:** Nicolas  
> **Status:** Done  
> {.is-success}

---

# Server — Developer Guide

This guide covers everything a new developer needs to start working on the Ascension
backend server. It complements the [architecture overview](./architecture.md) and
the [API routes reference](./api-routes.md).

---

## Table of Contents

- [Server — Developer Guide](#server--developer-guide)
  - [Table of Contents](#table-of-contents)
  - [Prerequisites](#prerequisites)
  - [Tech Stack](#tech-stack)
  - [Repository Layout](#repository-layout)
  - [Environment Variables](#environment-variables)
  - [Running Locally](#running-locally)
    - [1. Start the infrastructure](#1-start-the-infrastructure)
    - [2. Install sqlx-cli](#2-install-sqlx-cli)
    - [3. Run database migrations](#3-run-database-migrations)
    - [4. Start the server](#4-start-the-server)
  - [Moon Tasks Reference](#moon-tasks-reference)
  - [Database Migrations](#database-migrations)
  - [SQLx Offline Mode](#sqlx-offline-mode)
  - [Testing](#testing)
  - [Docker](#docker)
  - [Common Errors](#common-errors)

---

## Prerequisites

- **Rust** (toolchain pinned in `.prototools` — use `proto install rust` or `rustup`)
- **Docker** + **Docker Compose** — for PostgreSQL, RabbitMQ, MinIO locally
- **sqlx-cli** — used to run database migrations (see [below](#2-install-sqlx-cli))
- **moon** — monorepo task runner (see [Developer Quickstart](../README.md))

---

## Tech Stack

| Technology         | Version            | Role                                                  |
|--------------------|--------------------|-------------------------------------------------------|
| **Rust**           | 1.93.1             | Language                                              |
| **Axum**           | 0.8                | HTTP web framework                                    |
| **SQLx**           | 0.8                | Async PostgreSQL driver + compile-time query checking |
| **Tokio**          | 1.50               | Async runtime                                         |
| **PostgreSQL**     | 18                 | Relational database                                   |
| **RabbitMQ**       | 4.x                | Message broker (dispatches AI jobs)                   |
| **MinIO**          | RELEASE.2025-09-07 | S3-compatible object storage for videos               |
| **Serde**          | 1.0                | JSON serialization / deserialization                  |
| **jsonwebtoken**   | 10.3               | JWT creation and validation                           |
| **tower-governor** | 0.8                | Rate limiting (10 req/s per IP)                       |

---

## Repository Layout

```
apps/server/
├── Cargo.toml          # Rust package + all dependencies
├── Cargo.lock          # Exact dependency versions (committed)
├── .sqlx/              # Compile-time SQL query cache (offline mode)
├── migrations/         # SQL migration files, applied in timestamp order
├── moon.yml            # moon task definitions
└── src/
    ├── main.rs         # Entry point — wires all layers together
    ├── config.rs       # Reads all environment variables
    ├── domain/         # Business logic — models, ports (traits), services
    ├── inbound/        # HTTP layer — Axum router, handlers, middleware
    ├── outbound/       # Database adapters — SQLx / PostgreSQL
    ├── usecase/        # Cross-cutting use cases (auth / JWT)
    └── tests/          # Unit tests
```

For a deeper explanation of each layer, read the [architecture overview](./architecture.md).

---

## Environment Variables

Copy `.env.example` to `.env` at the repository root and fill in the values.
The server reads all of these at startup via `src/config.rs`.

| Variable              | Required | Default  | Description                                                                        |
|-----------------------|----------|----------|------------------------------------------------------------------------------------|
| `DATABASE_URL`        | ✅        | —        | PostgreSQL connection string, e.g. `postgres://user:pass@localhost:5432/ascension` |
| `JWT_KEY`             | ✅        | —        | Secret key for signing JWTs (use a long random string in production)               |
| `RABBITMQ_URL`        | ✅        | —        | AMQP URL, e.g. `amqp://ascension:ascension@localhost:5672`                         |
| `MINIO_ENDPOINT`      | ✅        | —        | MinIO base URL, e.g. `http://localhost:9000`                                       |
| `MINIO_ROOT_USER`     | ✅        | —        | MinIO access key                                                                   |
| `MINIO_ROOT_PASSWORD` | ✅        | —        | MinIO secret key                                                                   |
| `MINIO_BUCKET`        | ❌        | `videos` | Bucket name for video uploads                                                      |
| `SERVER_PORT`         | ❌        | `8080`   | TCP port to listen on                                                              |
| `RUN_MIGRATION`       | ❌        | `false`  | Set to `true` to auto-run migrations on startup                                    |

---

## Running Locally

### 1. Start the infrastructure

```bash
# From the repository root
docker compose up -d
```

This starts PostgreSQL (port 5432), RabbitMQ (port 5672 / 15672), and MinIO (port 9000 / 9001).

### 2. Install sqlx-cli

`sqlx-cli` is the command-line tool used to run database migrations.
You only need to do this **once** per machine.

```bash
moon run server:install-sqlx
```

This runs:

```bash
cargo install sqlx-cli --no-default-features --features native-tls,postgres
```

### 3. Run database migrations

```bash
moon run server:migrate
```

This applies all pending SQL files from `apps/server/migrations/` in order.
It is safe to run multiple times (already-applied migrations are skipped).

> Make sure your `.env` has a valid `DATABASE_URL` before running this.

### 4. Start the server

```bash
moon run server:dev
```

The server will start on port `8080` by default and reload on code changes is
**not** automatic — restart manually after changes.

To build and run the binary directly:

```bash
cargo run
```

---

## Moon Tasks Reference

Run these from the repository root with `moon run server:<task>`.

| Task            | Command                       | Description                             |
|-----------------|-------------------------------|-----------------------------------------|
| `install-sqlx`  | `cargo install sqlx-cli ...`  | Installs the sqlx CLI tool (run once)   |
| `migrate`       | `sqlx migrate run`            | Applies all pending DB migrations       |
| `dev`           | `cargo run`                   | Starts the server with `RUST_LOG=debug` |
| `build`         | `cargo build`                 | Debug build (uses `SQLX_OFFLINE=true`)  |
| `build-release` | `cargo build --release`       | Release build (runs lint first)         |
| `lint`          | `cargo clippy -- -D warnings` | Static analysis — fails on any warning  |
| `format`        | `cargo fmt --all`             | Auto-format all source files            |
| `format-check`  | `cargo fmt --all --check`     | Check formatting without writing        |
| `test`          | `cargo test`                  | Run all unit tests                      |

---

## Database Migrations

Migrations live in `apps/server/migrations/` and are named with a UTC timestamp prefix:

```
20260303132858_create_users_table.sql
20260307000001_create_videos_table.sql
20260307000002_create_analyses_table.sql
```

**To create a new migration:**

```bash
sqlx migrate add <description>
# e.g.
sqlx migrate add create_sessions_table
```

This creates a new file with the current timestamp. Write your `CREATE TABLE` SQL inside it.

**Rules:**

- Never edit a migration file that has already been applied — create a new one instead.
- Always test migrations locally before pushing.
- The `set_updated_at` trigger function (created in `create_users_table.sql`) is reusable in any migration.

---

## SQLx Offline Mode

SQLx checks SQL queries **at compile time** against the real database schema.
To allow building without a live database (e.g. in CI), the query metadata is
cached in `.sqlx/`.

If you add or change a `sqlx::query!` macro call, regenerate the cache:

```bash
# Make sure DATABASE_URL is set and the DB is running
cargo sqlx prepare
```

The updated files in `.sqlx/` must be committed to the repository.

If you see the error `sqlx::query! called with argument that doesn't implement Encode`,
it usually means the `.sqlx/` cache is out of date — re-run `cargo sqlx prepare`.

---

## Testing

Unit tests live in `src/tests/` and test the domain layer in isolation
using mock repositories (`mockall` crate).

```bash
moon run server:test
# or
cargo test
```

The test modules mirror the source structure:

```
src/tests/
├── mod.rs
└── domain/
    ├── mod.rs
    └── user/
        ├── model_tests.rs    # Username, Email, Password, Role validation
        └── service_tests.rs  # User CRUD service with mock repository
```

**Writing a new test:**

1. Add a new `mod` declaration in the relevant `mod.rs`.
2. Create a `mockall`-annotated mock for any trait your test depends on.
3. Annotate your test function with `#[tokio::test]` (async tests) or `#[test]` (sync).

---

## Docker

The server has a `Dockerfile` at `apps/server/Dockerfile`.

**Multi-stage build:**

1. `builder` — compiles the release binary with `SQLX_OFFLINE=true`.
2. `runtime` — copies only the binary and `migrations/` into a slim Debian image.

```bash
# Build the image locally
docker build -t ascension-server apps/server/

# Run it (requires an .env or explicit -e flags)
docker run --env-file .env -p 8080:8080 ascension-server
```

**In production**, use:

```bash
docker compose --profile prod up -d
```

This starts the server alongside PostgreSQL, RabbitMQ, MinIO, and the AI worker.
The server image is pulled from the GitHub Container Registry (`ghcr.io/ascension-eip/ascension-server`).

---

## Common Errors

| Error                                                        | Likely cause                          | Fix                                                   |
|--------------------------------------------------------------|---------------------------------------|-------------------------------------------------------|
| `error: DATABASE_URL must be set`                            | `.env` not loaded or missing variable | Copy `.env.example` to `.env` and fill `DATABASE_URL` |
| `sqlx: migrate error: table _sqlx_migrations does not exist` | First run, table will be created      | Normal on first `sqlx migrate run`                    |
| `Connection refused (os error 111)` on port 5432             | PostgreSQL not running                | `docker compose up -d`                                |
| `cargo build` fails with "offline mode" error                | `.sqlx/` cache out of date            | `cargo sqlx prepare` then commit `.sqlx/`             |
| `429 Too Many Requests` in tests                             | Rate limiter hitting                  | Space out requests or use a different IP              |
