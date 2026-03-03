# Routing Rules

## Domain Routing

| Domain / Keywords | Primary Agent | Secondary |
|-------------------|---------------|-----------|
| AI, vision, pipeline, MediaPipe, PyTorch, OpenCV, skeleton, ghost, hold detection, training program | Quentin | Eric (review) |
| API, Rust, Axum, endpoints, JWT, auth, SQLx, WebSocket, presigned URL | Renaud | Eric (review) |
| Flutter, mobile, UI, overlay, rendering, client, app, widget | Romaric | Eric (review) |
| Docker, CI/CD, GitHub Actions, deployment, Hetzner, Kubernetes, scaling | Arthur | Eric (review) |
| RabbitMQ, PostgreSQL, MinIO, S3, database, schema, queues, exchanges, buckets, storage | Alexandra | Eric (review) |
| Documentation, docs/, README, guides, specs, architecture docs | Darius | — |
| Architecture, system design, code review, technical decisions | Eric | — |

## Cross-Cutting Rules

- **Any code change** → Darius updates docs/ if the change touches a documented topic
- **Database schema changes** → Alexandra (implementation) + Darius (docs update)
- **New API endpoints** → Renaud (implementation) + Darius (API spec update)
- **Infrastructure changes** → Alexandra or Arthur depending on scope + Darius (deployment docs)
- **Multi-domain tasks** → Eric coordinates, spawns relevant agents

## Review Gates

- Eric reviews all architectural decisions
- Quentin reviews AI pipeline changes
- Renaud reviews API changes
- Alexandra reviews infrastructure/data changes
