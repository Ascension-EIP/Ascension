# Server Architecture

This document explains how the Ascension backend server is structured and why it is built that way.
No prior Rust or architecture knowledge is required to read this.

---

## Table of Contents

- [Server Architecture](#server-architecture)
  - [Table of Contents](#table-of-contents)
  - [Tech stack](#tech-stack)
  - [What is Hexagonal Architecture?](#what-is-hexagonal-architecture)
  - [The three layers of the server](#the-three-layers-of-the-server)
    - [Domain (the core)](#domain-the-core)
    - [Inbound (HTTP layer)](#inbound-http-layer)
    - [Outbound (database layer)](#outbound-database-layer)
  - [How a request flows through the server](#how-a-request-flows-through-the-server)
  - [File structure map](#file-structure-map)
  - [The entry point: `main.rs`](#the-entry-point-mainrs)
  - [Configuration: `config.rs`](#configuration-configrs)

---

## Tech stack

| Technology | Role |
|---|---|
| **Rust** | Programming language |
| **Axum** | HTTP web framework (like Express.js for Node) |
| **SQLx** | Database driver to talk to PostgreSQL |
| **Tokio** | Async runtime (lets the server handle many requests at once) |
| **PostgreSQL** | The database |
| **Serde** | Serialize/deserialize JSON |
| **Anyhow / Thiserror** | Error handling helpers |
| **UUID** | Generate unique IDs |

---

## What is Hexagonal Architecture?

Hexagonal architecture (also called **Ports & Adapters**) is a way of organizing code so that the core business logic is completely isolated from the outside world (HTTP, databases, etc.).

Think of it like this:

```
┌──────────────────────────────────────┐
│               OUTSIDE                │
│                                      │
│   HTTP Requests        Database      │
│   (Inbound)            (Outbound)    │
│         │                   ▲        │
│         ▼                   │        │
│    ┌─────────────────────────────┐   │
│    │         DOMAIN (Core)       │   │
│    │   Pure business logic only  │   │
│    │   Knows NOTHING about HTTP  │   │
│    │   Knows NOTHING about SQL   │   │
│    └─────────────────────────────┘   │
└──────────────────────────────────────┘
```

**The key rule:** the Domain never imports anything from Inbound or Outbound.
It only defines *what* it needs through **traits** (called "ports").
The Inbound and Outbound layers implement those traits ("adapters").

**Why?**

- You can swap PostgreSQL for a different database without touching a single line of business logic.
- You can test business logic without a real database or a real HTTP server.
- The code is easier to navigate: each layer has a clear responsibility.

---

## The three layers of the server

### Domain (the core)

**Location:** `src/domain/`

This is the heart of the application. It contains:

- **Models** – The data structures that represent your business entities (e.g., `User`, `Username`, `EmailAddress`). They include validation logic (e.g., a username must match `^[a-zA-Z0-9_]{8,24}$`).
- **Ports** – Rust `trait`s (interfaces) that describe what operations are available. There are two kinds:
  - `UserService` — what the HTTP layer can call (e.g., `create_user`).
  - `UserRepository` — what the database layer must implement (e.g., `create_user` at the SQL level).
- **Service** – The concrete implementation of `UserService`. It receives a repository, calls it, and maps the result to an output type.

The Domain answers the question: **"What does the application do?"**

---

### Inbound (HTTP layer)

**Location:** `src/inbound/http/`

This layer is responsible for:

1. **Listening** for incoming HTTP requests on a TCP port.
2. **Routing** requests to the right handler function.
3. **Parsing** the JSON request body into Rust types.
4. **Validating** those types (e.g., is the email address well-formed?).
5. **Calling** the Domain service.
6. **Formatting** the result as a JSON HTTP response.

Key files:

| File | Role |
|---|---|
| `src/inbound/http.rs` | Builds the Axum router, binds to the port, starts the server |
| `src/inbound/http/handlers/api.rs` | Generic `ApiSuccess<T>` and `ApiError` response wrappers |
| `src/inbound/http/handlers/status.rs` | The `GET /` health-check endpoint |
| `src/inbound/http/handlers/user/create_user.rs` | Handler for `POST /api/users` |

The Inbound layer answers the question: **"How does the outside world talk to the application?"**

---

### Outbound (database layer)

**Location:** `src/outbound/`

This layer is responsible for persisting data. Currently there is one adapter:

| File | Role |
|---|---|
| `src/outbound/postgresql.rs` | Implements `UserRepository` using SQLx + PostgreSQL |

The `Postgres` struct holds a connection pool and executes SQL queries. It maps database results back to Domain models (`User`, etc.).

The Outbound layer answers the question: **"How does the application store and retrieve data?"**

---

## How a request flows through the server

Here is what happens step-by-step when a client sends `POST /api/users`:

```
Client
  │
  │  POST /api/users  { "username": "...", "email": "...", ... }
  ▼
Axum Router  (src/inbound/http.rs)
  │
  │  routes to create_user handler
  ▼
Handler: create_user()  (src/inbound/http/handlers/user/create_user.rs)
  │
  │  1. Deserializes JSON body → CreateUserHttpRequestBody
  │  2. Validates & converts → CreateUserInput  (domain type)
  │  3. Returns ApiError 422 if validation fails
  ▼
Service: Service::create_user()  (src/domain/user/service.rs)
  │
  │  1. Converts CreateUserInput → CreateUserData  (repo type)
  │  2. Calls self.repo.create_user(...)
  ▼
Repository: Postgres::create_user()  (src/outbound/postgresql.rs)
  │
  │  1. Opens a database transaction
  │  2. Executes INSERT INTO users ...
  │  3. Commits transaction
  │  4. Returns User struct on success
  │     or UserRepositoryError on failure
  ▼
Service  (back in service.rs)
  │
  │  Maps User → CreateUserOutput { id }
  │  Maps UserRepositoryError → CreateUserError
  ▼
Handler  (back in create_user.rs)
  │
  │  Maps CreateUserOutput → CreateUserResponse { id: String }
  │  Maps CreateUserError → ApiError
  ▼
Axum  →  HTTP 201 { "status_code": 201, "data": { "id": "..." } }
  │
  ▼
Client
```

> **Notice** that each layer only knows about the *next* layer's **trait** (interface), not its concrete type.
> The handler knows about `UserService` (a trait). The service knows about `UserRepository` (a trait).
> This is the "ports & adapters" pattern in action.

---

## File structure map

```
apps/server/
├── Cargo.toml                          # Rust project & dependencies
├── migrations/                         # SQL migration files (run once to create tables)
└── src/
    ├── main.rs                         # Entry point: wires everything together
    ├── config.rs                       # Reads environment variables
    │
    ├── domain.rs                       # Re-exports domain module
    ├── domain/
    │   └── user/
    │       ├── user.rs                 # Re-exports models, ports, service
    │       ├── models/
    │       │   └── user.rs             # User struct + value types + Input/Output/Error types
    │       ├── ports.rs                # UserService trait + UserRepository trait + data structs
    │       └── service.rs              # Service<R> — implements UserService, calls the repo
    │
    ├── inbound.rs                      # Re-exports inbound module
    ├── inbound/
    │   └── http.rs                     # HttpServer, AppState, Axum router + routes
    │   └── http/
    │       └── handlers.rs             # Re-exports handlers
    │       └── handlers/
    │           ├── api.rs              # ApiSuccess<T> and ApiError generic wrappers
    │           ├── status.rs           # GET / health check
    │           ├── user.rs             # Re-exports user handlers
    │           └── user/
    │               └── create_user.rs  # POST /api/users
    │               └── (others in progress...)
    │
    ├── outbound.rs                     # Re-exports outbound module
    └── outbound/
        └── postgresql.rs              # Postgres struct — implements UserRepository
```

---

## The entry point: `main.rs`

`main.rs` is the only place where everything is assembled together. It:

1. Loads environment variables via `dotenv`.
2. Reads the configuration (`Config::load()`).
3. Creates the database connection pool (`Postgres::new(...)`).
4. Creates the domain service (`Service::new(db)`) — passing the database as the repository.
5. Creates and runs the HTTP server (`HttpServer::new(user_service, config)`).

```rust
// main.rs (simplified)
let db = Postgres::new(&config.database_url).await?;   // outbound adapter
let user_service = Service::new(db);                   // domain service
let http_server = HttpServer::new(user_service, ...).await?;
http_server.run().await
```

Notice that `main.rs` is the **only** file that knows about all three layers at the same time.
Every other file only knows about its own layer and the traits of adjacent ones.

---

## Configuration: `config.rs`

The server reads its configuration from **environment variables** (or a `.env` file).

| Variable | Required | Default | Description |
|---|---|---|---|
| `DATABASE_URL` | ✅ Yes | — | PostgreSQL connection string |
| `JWT_KEY` | ✅ Yes | — | Secret key for signing JWTs |
| `SERVER_PORT` | ❌ No | `8080` | Port the server listens on |
| `RUN_MIGRATION` | ❌ No | `false` | Run DB migrations on startup |

Example `.env` file:

```env
DATABASE_URL=postgres://user:password@localhost:5432/ascension
JWT_KEY=a-very-long-and-secret-random-string
SERVER_PORT=8080
RUN_MIGRATION=false
```
