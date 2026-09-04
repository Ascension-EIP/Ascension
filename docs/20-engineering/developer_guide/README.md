> **Last updated:** 9th March 2026
> **Version:** 1.2
> **Authors:** Nicolas
> **Status:** Done
> {.is-success}

---

# Developer Quickstart

Welcome to the Ascension developer guide. This document provides a quick reference
for setting up your development environment and links to all domain-specific guides.

---

## Table of Contents

- [Prerequisites & Installation](#prerequisites--installation)
- [Repository Setup](#repository-setup)
- [Environment Variable Strategy](#environment-variable-strategy)
- [Documentation Index](#documentation-index)

---

## Prerequisites & Installation

### 1. Moonrepo

Ascension uses [moonrepo](https://moonrepo.dev) as a monorepo management tool and task runner. It is recommended to install it via [proto](https://moonrepo.dev/proto), moonrepo's toolchain manager.

**Installation:**

```bash
# Install proto (Toolchain Manager)
curl -fsSL https://moonrepo.dev/install/proto.sh | bash

# Install moon using proto
proto install moon
```

### 2. uv (Python package & environment manager)

The AI services use [uv](https://docs.astral.sh/uv/) to manage Python dependencies and the virtual environment.

**Installation (Linux):**

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
# Or via your package manager, e.g.:
# brew install uv
```

### 3. Flutter

The mobile application is built with Flutter.

**Installation:**

1. Follow the [official Flutter installation guide](https://docs.flutter.dev/get-started/install/linux) for Linux.
2. Ensure the `flutter` binary is in your `PATH`.
3. Install the **Flutter** and **Dart** extensions in VS Code.
4. Run `flutter doctor` to verify your setup.

---

## Repository Setup

1. **Clone the repository:**

   ```bash
   git clone https://github.com/Ascension-EIP/Ascension.git
   cd Ascension
   ```

2. **Configure Environment:**

   ```bash
   cp .env.example .env
   # Edit .env if needed
   ```

3. **Start Infrastructure (databases, message broker, object storage):**

   ```bash
   docker compose up -d
   ```

4. **Initialize AI Environment and download the MediaPipe model:**

   ```bash
   moon run ai:setup
   moon run ai:download-model
   ```

   `ai:setup` runs `uv sync` to create the virtual environment and install all dependencies.

5. **Install sqlx-cli and run database migrations (server):**
   ```bash
   moon run server:install-sqlx
   moon run server:migrate
   ```

---

## Environment Variable Strategy

We follow a dual-strategy for environment variables to balance local developer experience with production security and reliability.

### Local Development

- **Source:** Root [.env](/.env) file.
- **Hostnames:** Uses `localhost` for services (PostgreSQL, RabbitMQ, MinIO).
- **Behavior:** Ports are forwarded from Docker containers to your machine, allowing local processes (like a `moon run ai:dev` task) to connect via `localhost`.

### Production (`--profile prod`)

- **Source:** Hardcoded in [docker-compose.yml](/docker-compose.yml) under the `environment` section for the `ai-worker`.
- **Hostnames:** Uses internal Docker network hostnames (e.g., `RABBITMQ_HOST=rabbitmq`).
- **Behavior:** This ensures seamless cross-container communication within the Docker network and prevents accidental `.env` leaks into the production container environment.

---

## Documentation Index

### Architecture & Roadmap

- [System Overview](./architecture/system-overview.md) — global architecture, data flows, scaling
- [Plan d'Action Technique](./plan-d-action-technique.md) — audit global, alignement des contrats API, parité backend et roadmap de refonte mobile

### Server (Go / Gin)

- [Developer Guide](./server/README.md) — setup, env vars, moon tasks, Docker
- [Architecture](./server/architecture.md) — hexagonal architecture, layers, request flow
- [API Routes Reference](./server/api-routes.md) — all HTTP routes with examples
- [How to Add a Route](./server/adding-a-route.md) — step-by-step guide
- [How to Implement a CRUD](./server/implementing-a-crud.md) — full domain-to-HTTP walkthrough

### AI Worker (Python / MediaPipe)

- [Developer Guide](./ai/README.md) — setup, pipelines, RabbitMQ, pose analysis

### Mobile (Flutter / Dart)

- [Developer Guide](./mobile/README.md) — setup, screens, navigation, API integration
