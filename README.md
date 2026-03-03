> **Last updated:** 3rd March 2026  
> **Version:** 2.0  
> **Authors:** Gianni TUERO, Nicolas TORO  
> **Status:** Done  
> {.is-success}  

---

# Ascension

**AI-powered climbing coach — objective technique analysis, personalized feedback.**

[![Flutter](https://img.shields.io/badge/Mobile-Flutter%20%2F%20Dart-02569B?logo=flutter)](https://flutter.dev)
[![Rust](https://img.shields.io/badge/API-Rust%20%2F%20Axum-DEA584?logo=rust)](https://www.rust-lang.org)
[![Python](https://img.shields.io/badge/AI-Python%20%2F%20MediaPipe-3776AB?logo=python)](https://python.org)
[![PostgreSQL](https://img.shields.io/badge/DB-PostgreSQL%2016-336791?logo=postgresql)](https://postgresql.org)

---

## Table of Contents

- [Ascension](#ascension)
  - [Table of Contents](#table-of-contents)
  - [What is Ascension?](#what-is-ascension)
  - [Core Features](#core-features)
  - [Repository Structure](#repository-structure)
  - [Tech Stack](#tech-stack)
  - [Getting Started](#getting-started)
  - [Usefull Documentation](#usefull-documentation)
  - [Contributing](#contributing)

---

## What is Ascension?

Ascension is a mobile application that analyzes climbing videos using computer vision and AI to deliver concrete, objective feedback on technique — the kind of feedback that usually requires a professional coach standing next to you.

Film yourself on the wall. Upload the video. Get a biomechanical breakdown of your movement, joint-by-joint coaching advice, and an optional ghost overlay comparing your path to the optimal line for your morphology.

**The problem we solve:** Professional climbing coaching is expensive (50 €/hour), subjective, and hard to access. Most climbers train without real feedback and only correct bad habits when they plateau or get injured. Ascension makes expert-level analysis available to any climber — from beginner to competition level — at a fraction of the cost.

---

## Core Features

| Feature                 | Description                                                             |   Tier   |
| :---------------------- | :---------------------------------------------------------------------- | :------: |
| **Skeleton Extraction** | 33-point pose estimation per frame (joint angles, center of gravity)    |   All    |
| **Coaching Advice**     | Move-by-move targeted feedback combining skeleton data + hold positions |   All    |
| **Hold Detection**      | AI classifies holds from a route photo; manual correction supported     |   All    |
| **Training Programs**   | Personalized routines from level, goals, and analysis history           |   All    |
| **Ghost Climber**       | Optimal path overlay rendered frame-by-frame on the user's video        | Premium+ |

---

## Repository Structure

This is a **monorepo** managed by [moonrepo](https://moonrepo.dev), containing all services in a single repository.

```
Ascension/
├── .moon/                  # moonrepo workspace & toolchain config
├── docker-compose.yml      # Local development orchestration
├── apps/
│   ├── server/             # Rust / Axum REST API + WebSocket
│   ├── mobile/             # Flutter mobile app (iOS & Android)
│   └── ai/                 # Python AI workers (MediaPipe, OpenCV)
└── docs/                   # All project documentation
```

Each app under `apps/` is independently buildable and deployable. See the [Monorepo Guide](docs/developer_guide/architecture/monorepo-guide.md) for the full structure, moonrepo task conventions, and CI/CD workflow.

---

## Tech Stack

| Layer          | Technology                                                   |
| :------------- | :----------------------------------------------------------- |
| Mobile         | Flutter (Dart) — `CustomPainter` for local overlay rendering |
| API            | Rust, Axum, Tokio, SQLx — JWT auth, REST + WebSocket         |
| AI Workers     | Python 3.10+, MediaPipe, PyTorch, OpenCV                     |
| Message Queue  | RabbitMQ 3.x — async job dispatch between API and workers    |
| Database       | PostgreSQL 16 — JSONB for analysis results                   |
| Object Storage | MinIO (dev) / Hetzner Storage Box (prod) — S3-compatible     |
| Infrastructure | Hetzner Cloud (EU), Docker Compose → Kubernetes              |
| Monorepo       | moonrepo                                                     |

For the full rationale behind every technology choice, see the [Architecture Decision Record](docs/developer_guide/architecture/README.md).

---

## Getting Started

> Full step-by-step instructions, prerequisites, and environment variables are in the **[Development Environment Setup](docs/developer_guide/architecture/deployment/development.md)** guide.

**Quick start (local dev):**

```bash
# 1. Clone
git clone https://github.com/Ascension-EIP/Ascension.git
cd Ascension

# 2. Install moonrepo
curl -fsSL https://moonrepo.dev/install/moon.sh | bash

# 3. Copy environment template and fill in values
cp .env.example .env

# 4. Start infrastructure (PostgreSQL, RabbitMQ, MinIO)
docker compose up -d

# 5. Run a service
moon run server:dev     # Rust API
moon run ai:dev         # Python AI worker
```

For production deployment, see the [Production Setup Guide](docs/developer_guide/architecture/deployment/production.md).

---

## Documentation

| Topic                     | Document                                                                                   |
| :------------------------ | :----------------------------------------------------------------------------------------- |
| Architecture overview     | [Architecture README](docs/developer_guide/architecture/README.md)                         |
| System design & patterns  | [System Overview](docs/developer_guide/architecture/system-overview.md)                    |
| Monorepo & moonrepo guide | [Monorepo Guide](docs/developer_guide/architecture/monorepo-guide.md)                      |
| Database schema & ERD     | [Database Schema](docs/developer_guide/architecture/specifications/database-schema.md)     |
| API specification         | [API Specification](docs/developer_guide/architecture/specifications/api-specification.md) |
| Development environment   | [Dev Setup](docs/developer_guide/architecture/deployment/development.md)                   |
| Production deployment     | [Production Setup](docs/developer_guide/architecture/deployment/production.md)             |
| Git branch conventions    | [Branch Standards](docs/git/git-branch-standards-guide.md)                                 |
| Git commit conventions    | [Commit Standards](docs/git/git-commit-standards-guide.md)                                 |
| Markdown style guide      | [Markdown Guidelines](docs/guidelines/markdown-guidelines.md)                              |

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for branching rules, commit conventions, pull request process, and code style requirements.

For security issues, see [SECURITY.md](SECURITY.md). For questions or bug reports, see [SUPPORT.md](SUPPORT.md).
