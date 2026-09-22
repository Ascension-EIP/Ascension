---
id: bd9a6ebc-77ef-4e23-8f13-827f20b7b945
sort: custom
order:
  - glossary
  - guidelines
  - git
  - agents
  - architecture
  - apps
---

:::success
**Version:** 1.0
:::

---

# Developer Documentation

Welcome to the **Ascension Developer Documentation** hub.

Ascension is an open, extensible climbing analysis platform built as a high-performance monorepo. This documentation provides engineering teams and contributors with the technical architecture, development workflows, standards, and component specifications needed to build, maintain, and scale the Ascension ecosystem.

:::info
**Language Standard:** All developer documentation is written **strictly in English** to maintain consistency across the codebase, Git history, issue trackers, and international developer tooling.
:::

---

## Technical Stack Overview

Ascension follows an **event-driven, decoupled architecture** managed as a monorepo via [moonrepo](https://moonrepo.dev):

| Subsystem | Technology | Responsibility |
| --- | --- | --- |
| **Mobile Client** (`apps/mobile`) | Flutter / Dart (`^3.11.0`) | Cross-platform mobile app (iOS & Android) with Forui UI design system and client-side canvas overlay rendering. |
| **API Gateway** (`apps/server`) | Go (`1.26.0`), Gin, pgx | High-throughput REST API, JWT authentication, WebSocket live updates, and MinIO presigned URL dispatch. |
| **AI Workers** (`apps/ai`) | Python `3.11`, MediaPipe, PyTorch, OpenCV | Asynchronous computer vision pipelines: 2D/3D skeleton extraction, hold detection, and biomechanical qualification. |
| **Message Broker** | RabbitMQ `4.2.4` | Reliable AMQP task queues decoupling the API Gateway from compute-heavy AI processing workers. |
| **Database** | PostgreSQL `18` | Relational data persistence, user accounts, subscription quotas, and JSONB analysis results. |
| **Object Storage** | MinIO (Dev) / S3-compatible | Storage for raw climb videos, processed media assets, and thumbnail previews. |

---

## Documentation Structure

The developer documentation is organized into six core modules:

### 1\. [glossary](glossary.md)

Shared domain vocabulary bridging climbing fundamentals (*beta*, *crux*, *crimp*, *sloper*), biomechanical metrics (center of mass, joint angles, center of gravity), and system architecture concepts.

### 2\. [Guidelines](guidelines/readme.md)

Engineering standards and formatting conventions enforced across the repository, including:

- [Markdown Guidelines](guidelines/markdown-guidelines.md): Heading hierarchy, status containers, Prettier rules, and accessibility standards.
- Code quality bars, testing expectations, and linting guidelines.

### 3\. [Git & GitHub Standards](git/readme.md)

Team collaboration conventions and automated developer workflows:

- **Branching:** Git branch naming conventions (`feature/`, `fix/`, `docs/`, `chore/`).
- **Commits:** Conventional Commits specification rules.
- **Issue Tracking:** GitHub issue labeling and template standards.
- **Automation:** GitHub Actions CI/CD workflows and automated pre-commit hooks.

### 4\. [AI Agents & Tooling](agents/readme.md)

Pre-prompts, system configurations, and tool integrations for AI coding assistants (Claude Code, GitHub Copilot, Antigravity) supporting the Ascension project.

### 5\. [System Architecture](architecture/readme.md)

Deep-dive into the architectural decisions that power the platform:

- **Global Architecture & Overview:** High-level system topology, CQRS principles, and event-driven data flows.
- **Monorepo Guide:** Workspace setup and task orchestration using `moonrepo`.
- **Specifications:** Complete PostgreSQL database schemas (ERD) and REST API contracts.
- **Deployment Guides:** Step-by-step instructions for local development and cloud production deployment.

### 6\. [Applications (`apps`)](apps/readme.md)

Implementation details and dedicated guides for each service in the repository:

- **`mobile`:** State management, Forui design library usage, camera integration, and edge-rendered `CustomPainter` overlays.
- **`server`:** Route registration, CRUD implementation patterns, middleware, and Swagger documentation generation.
- **`ai`:** Pose estimation models, hold segmentation algorithms, and AMQP consumer lifecycle.

---

## Quick Start for Developers

```bash
# 1. Clone the repository
git clone https://github.com/Ascension-EIP/Ascension.git
cd Ascension

# 2. Configure local environment variables
cp .env.example .env

# 3. Start local infrastructure services (Postgres, RabbitMQ, MinIO)
docker compose up -d

# 4. Run any service via moonrepo
moon run server:dev     # Starts Go API
moon run ai:dev         # Starts Python AI workers
moon run mobile:dev     # Launches Flutter mobile app
```

---

## Navigation

:::subpages cards 3
