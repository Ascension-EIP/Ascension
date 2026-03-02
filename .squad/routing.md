# Routing Rules

## Domain Routing

| Domain / Keywords | Primary Agent | Secondary |
|-------------------|---------------|-----------|
| AI, vision, pipeline, MediaPipe, PyTorch, OpenCV, skeleton, ghost, hold detection, training program | Gandalf | Aragorn (review) |
| API, Rust, Axum, endpoints, JWT, auth, SQLx, WebSocket, presigned URL | Boromir | Aragorn (review) |
| Flutter, mobile, UI, overlay, rendering, client, app, widget | Legolas | Aragorn (review) |
| Docker, CI/CD, GitHub Actions, deployment, Hetzner, Kubernetes, scaling | Samwise | Aragorn (review) |
| RabbitMQ, PostgreSQL, MinIO, S3, database, schema, queues, exchanges, buckets, storage | Gimli | Aragorn (review) |
| Documentation, docs/, README, guides, specs, architecture docs | Bilbo | — |
| Architecture, system design, code review, technical decisions | Aragorn | — |

## Cross-Cutting Rules

- **Any code change** → Bilbo updates docs/ if the change touches a documented topic
- **Database schema changes** → Gimli (implementation) + Bilbo (docs update)
- **New API endpoints** → Boromir (implementation) + Bilbo (API spec update)
- **Infrastructure changes** → Gimli or Samwise depending on scope + Bilbo (deployment docs)
- **Multi-domain tasks** → Aragorn coordinates, spawns relevant agents

## Review Gates

- Aragorn reviews all architectural decisions
- Gandalf reviews AI pipeline changes
- Boromir reviews API changes
- Gimli reviews infrastructure/data changes
