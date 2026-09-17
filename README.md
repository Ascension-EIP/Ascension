:::success
**Version:** 2.0  
**Original language:** English  
:::

---

# Ascension

**AI-powered climbing coach — objective technique analysis, personalized feedback.**

[![Flutter](https://img.shields.io/badge/Mobile-Flutter%20%2F%20Dart-02569B?logo=flutter)](https://flutter.dev)
[![Go](https://img.shields.io/badge/API-Go%20%2F%20Gin-00ADD8?logo=go)](https://go.dev)
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

| Feature | Description | Phase |
| :--- | :--- | :---: |
| **Morphological Profile** | Tailored body setup (height, weight, limbs) and interactive injury/amputation map | BTP |
| **Video Analysis & Feedback** | Objective climb analysis from video with key movement breakdowns | MVP -> BTP |
| **Skeleton Extraction (2D/3D)** | 33-point pose estimation (MediaPipe) in 2D, moving to 3D pose AI | MVP -> ATP |
| **Global Score & Progress** | Session-by-session technical scores and long-term progress metrics | BTP |
| **Ghost Mode (Comparison & Photo)** | Optimal path overlay on video or wall photo based on user morphology | BTP -> ATP |
| **Hold Detection & Analysis** | Automatic hold qualification and contouring with manual fallback | ATP |
| **Interactive 3D Experience** | Interactive 3D scene (orbit, pan, zoom) for movement inspection | ATP |
| **Targeted Coaching Advice** | Contextualized actionable technical feedback powered by LLM (Gemini API) | BTP |
| **Training Programs & Routines** | Personalized routines adapted to level, goals, injuries, and history | BTP |
| **Community & Sharing** | Climb sharing, friend performance comparison, and fine-grained privacy controls | BTP |
| **Assisted Climbing (AR + Audio)** | Real-time ascent tracking with audio coaching cues through earphones | ATP |
| **Subscriptions & Quotas** | Flexible tiers (Freemium, Premium, Infinity) with transparent quotas | ATP |

---

## Repository Structure

This is a **monorepo** managed by [moonrepo](https://moonrepo.dev), containing all services in a single repository.

```
Ascension/
├── .moon/                  # moonrepo workspace & toolchain config
├── docker-compose.yml      # Local development orchestration
├── apps/
│   ├── server/             # Go / Gin REST API + WebSocket
│   ├── mobile/             # Flutter mobile app (iOS & Android)
│   └── ai/                 # Python AI workers (MediaPipe, OpenCV)
└── docs/                   # All project documentation
```

Each app under `apps/` is independently buildable and deployable. See the [Monorepo Guide](docs/engineering/developer_guide/architecture/monorepo-guide.md) for the full structure, moonrepo task conventions, and CI/CD workflow.

---

## Tech Stack

| Layer          | Technology                                                   |
| :------------- | :----------------------------------------------------------- |
| Mobile         | Flutter (Dart) — `CustomPainter` for local overlay rendering |
| API            | Go, Gin, pgx — JWT auth, REST + WebSocket         |
| AI Workers     | Python 3.11, MediaPipe, PyTorch, OpenCV                     |
| Message Queue  | RabbitMQ 4.2.4 — async job dispatch between API and workers    |
| Database       | PostgreSQL 18 — JSONB for analysis results                   |
| Object Storage | MinIO (dev) / Hetzner Storage Box (prod) — S3-compatible     |
| Infrastructure | Hetzner Cloud (EU), Docker Compose → Kubernetes              |
| Monorepo       | moonrepo                                                     |

For the full rationale behind every technology choice, see the [Architecture Decision Record](docs/engineering/developer_guide/architecture/readme.md).

---

## Getting Started

> Full step-by-step instructions, prerequisites, and environment variables are in the **[Development Environment Setup](docs/engineering/developer_guide/architecture/deployment/development.md)** guide.

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
moon run server:dev     # Go API
moon run ai:dev         # Python AI worker
```

For production deployment, see the [Production Setup Guide](docs/engineering/developer_guide/architecture/deployment/production.md).

---

## Documentation

| Topic                     | Document                                                                                                 |
| :------------------------ | :------------------------------------------------------------------------------------------------------- |
| Architecture overview     | [Architecture README](docs/engineering/developer_guide/architecture/readme.md)                         |
| System design & patterns  | [System Overview](docs/engineering/developer_guide/architecture/system-overview.md)                  |
| Monorepo & moonrepo guide | [Monorepo Guide](docs/engineering/developer_guide/architecture/monorepo-guide.md)                    |
| Database schema & ERD     | [Database Schema](docs/engineering/developer_guide/architecture/specifications/database-schema.md)   |
| API specification         | [API Specification](docs/engineering/developer_guide/architecture/specifications/api-specification.md)|
| Development environment   | [Dev Setup](docs/engineering/developer_guide/architecture/deployment/development.md)                 |
| Production deployment     | [Production Setup](docs/engineering/developer_guide/architecture/deployment/production.md)           |
| Git branch conventions    | [Branch Standards](docs/engineering/git/git-branch-standards-guide.md)                               |
| Git commit conventions    | [Commit Standards](docs/engineering/git/git-commit-standards-guide.md)                               |
| Markdown style guide      | [Markdown Guidelines](docs/start-here/guidelines/markdown-guidelines.md)                            |

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for branching rules, commit conventions, pull request process, and code style requirements.

For security issues, see [SECURITY.md](SECURITY.md). For questions or bug reports, see [SUPPORT.md](SUPPORT.md).
