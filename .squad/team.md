# Ascension — Squad Team

## Project Context

**Project:** Ascension — Climbing video analysis platform
**Stack:** Flutter (mobile), Rust/Axum (API Gateway), Python/PyTorch/MediaPipe/OpenCV (AI Workers), RabbitMQ (messaging), PostgreSQL (database), MinIO/S3 (object storage), Docker Compose
**User:** Gianni TUERO
**Created:** 2026-03-02

## Members

| Name | Role | Scope | Emoji |
|------|------|-------|-------|
| Aragorn | Lead | Architecture, code review, technical decisions | 🏗️ |
| Gandalf | AI Dev | Python, PyTorch, MediaPipe, OpenCV, vision & training pipelines | 🤖 |
| Boromir | Backend Dev | Rust, Axum, JWT, SQLx, WebSockets, API Gateway | 🔧 |
| Legolas | Mobile Dev | Flutter, UI, overlay rendering, client-side | 📱 |
| Samwise | DevOps | Docker, CI/CD, GitHub Actions, Hetzner deployment | ⚙️ |
| Gimli | Infra | RabbitMQ, PostgreSQL, MinIO/S3, data persistence | 🗄️ |
| Bilbo | Docs | Documentation, keeps docs/ in sync with all changes | 📝 |
| Scribe | Session Logger | Memory, decisions, session logs | 📋 |
| Ralph | Work Monitor | Work queue, backlog, keep-alive | 🔄 |

## Architecture Overview

- **Layer 1:** Flutter mobile app — video capture, overlay rendering, WebSocket
- **Layer 2:** Rust API Gateway (Axum) — auth, validation, presigned URLs, job orchestration
- **Layer 3:** RabbitMQ — job queues (vision.*, training.*), event routing
- **Layer 4:** Python AI Workers — hold detection, skeleton extraction, advice, ghost mode, training programs
- **Layer 5:** PostgreSQL (structured data) + MinIO/S3 (video/object storage)

## Key Patterns

- Event-Driven Architecture
- CQRS (Command Query Responsibility Segregation)
- Client-Side Rendering (JSON overlays, not re-encoded video)
- Presigned URL uploads (client → S3 direct)
- WebSocket notifications for async job completion
