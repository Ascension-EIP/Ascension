> **Last updated:** 9th March 2026  
> **Version:** 1.1  
> **Authors:** Nicolas  
> **Status:** Done  
> {.is-success}

---

# Server Architecture

This document explains how the Ascension backend server is structured and why it is built that way.
No prior Go or architecture knowledge is required to read this.

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
  - [The entry point: `main.go`](#the-entry-point-maingo)
  - [Configuration: `config.go`](#configuration-configgo)

---

## Tech stack

| Technology | Role |
|---|---|
| **Go** | Programming language |
| **Gin** | HTTP web framework |
| **pgx/v5** | Database driver/pool to talk to PostgreSQL |
| **Goroutines** | Concurrency handling |
| **PostgreSQL** | The database |
| **JSON** | Native json tag support in structs |
| **UUID** | Google UUID package for Go |

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

- The core business logic is completely isolated from HTTP routers, database queries, and message brokers.
- The domain layer defines **interfaces** (ports) for repositories and services.
- The inbound and outbound layers implement these interfaces (adapters).

---

## The three layers of the server

### Domain (the core)

**Location:** `internal/model/` and `internal/service/`

This is the heart of the application. It contains:

- **Models** – The data structures that represent your business entities (e.g., `User`, `Video`, `Analysis`).
- **Interfaces** – Go interfaces (ports) defined directly in services (e.g., `userRepository` in `internal/service/user.go`) describing what database operations are required.
- **Service** – The concrete implementation of business services. It orchestrates the business workflows (e.g. hashing passwords, calling repositories, publishing RabbitMQ events).

---

### Inbound (HTTP layer)

**Location:** `internal/inbound/http/`

This layer is responsible for:

1. **Listening** for incoming HTTP requests on a TCP port.
2. **Routing** requests to the right handler function using the Gin router.
3. **Parsing** the JSON request body into DTO structs.
4. **Validating** those structs.
5. **Calling** the Domain service.
6. **Formatting** the result as a JSON HTTP response.

Key folders/files:

| Path | Role |
|---|---|
| `internal/inbound/http/router/router.go` | Wires up the Gin router, middleware, and routes |
| `internal/inbound/http/handler/` | Controllers/handlers for each resource (e.g. `user.go`, `auth.go`) |
| `internal/inbound/http/middleware/` | Rate limiters, JWT authorization, recovery, and logging middleware |

---

### Outbound (adapters)

**Location:** `internal/outbound/`

This layer is responsible for persisting data and communicating with external systems. It contains:

| Path | Role |
|---|---|
| `internal/outbound/postgres/` | Implements database repositories using pgx |
| `internal/outbound/rabbitmq/` | Client for publishing and consuming queue events |
| `internal/outbound/minio/` | Client for generating presigned upload/download URLs |

---

Here is what happens step-by-step when a client sends `POST /v1/users`:

```
Client
  │
  │  POST /v1/users  { "username": "...", "email": "...", ... }
  ▼
Gin Router  (internal/inbound/http/router/router.go)
  │
  │  routes to Create handler
  ▼
Handler: UserHandler.Create()  (internal/inbound/http/handler/user.go)
  │
  │  1. Binds JSON body → SignupLoginForm DTO
  │  2. Validates fields (checks email pattern, password length)
  │  3. Converts to domain model
  ▼
Service: UserService.CreateUser()  (internal/service/user.go)
  │
  │  1. Hashes user password using bcrypt
  │  2. Calls s.r.CreateUser(...)  (interface call)
  ▼
Repository: UserRepository.CreateUser()  (internal/outbound/postgres/user.go)
  │
  │  1. Executes INSERT INTO users ... using pgxpool
  │  2. Returns User struct on success or error on failure
  ▼
Service  (back in user.go)
  │
  │  Returns created User and nil error
  ▼
Handler  (back in user.go)
  │
  │  1. Maps User → response.User DTO
  │  2. Serializes DTO to JSON and returns HTTP 201
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
├── cmd/
│   └── server/
│       └── main.go                     # Entry point: wires everything together
├── go.mod                              # Go module definition
├── go.sum                              # Go dependency checksums
├── migrations/                         # SQL migration files (run on startup)
└── internal/
    ├── app/
    │   └── app.go                      # Application orchestrator / runner
    ├── model/                          # Domain models (entities & value objects)
    │   ├── analysis.go
    │   ├── auth.go
    │   ├── user.go
    │   └── video.go
    ├── service/                        # Domain services (business logic & port definitions)
    │   ├── analysis.go
    │   ├── auth.go
    │   ├── user.go
    │   └── video.go
    ├── inbound/                        # HTTP controllers / adapters
    │   └── http/
    │       ├── dto/                    # Data Transfer Objects for request/response binding
    │       ├── handler/                # Gin router handlers (controllers)
    │       ├── middleware/             # Gin middleware (auth, recovery, logger)
    │       └── router/                 # Router configuration
    └── outbound/                       # Adapters for database, message queue, and object storage
        ├── postgres/                   # PostgreSQL storage repository (pgx implementation)
        ├── rabbitmq/                   # RabbitMQ message broker client
        └── minio/                      # MinIO (S3) file storage client
```

---

## The entry point: `main.go`

`main.go` is the place where everything is wired together:

1. Loads configuration (`config.Load()`).
2. Creates the postgres repository connection (`postgres.New()`).
3. Creates the domain services, injecting the repository.
4. Initializes the Gin HTTP server router and runs it.

---

## Configuration: `config.go`

The server reads its configuration from environment variables.

| Variable | Required | Default | Description |
|---|---|---|---|
| `DB_NAME` | ✅ Yes | — | Database name |
| `DB_USER` | ✅ Yes | — | Database user |
| `DB_PASS` | ✅ Yes | — | Database password |
| `DB_HOST` | ❌ No | `localhost` | Database host |
| `DB_PORT` | ❌ No | `5432` | Database port |
| `DB_MIGRATION` | ❌ No | — | Migrations directory |
