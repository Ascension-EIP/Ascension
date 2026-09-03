# Ridjan — History

## Project Context (Day 1)

**Project:** Ascension — Climbing video analysis platform
**User:** Gianni TUERO

**Stack:**
- Flutter (mobile) — video capture, overlay rendering, WebSocket
- Go/Gin (API Gateway) — auth, JWT, pgx, presigned URLs, job orchestration
- Python/PyTorch/MediaPipe/OpenCV (AI Workers) — hold detection, skeleton, advice, ghost mode
- RabbitMQ — job queues (vision.*, training.*), event routing
- PostgreSQL — structured data
- MinIO/S3 — video and object storage
- Docker Compose — orchestration

**Key patterns:** Event-Driven Architecture, CQRS, Client-Side Rendering, Presigned URL uploads, WebSocket async notifications

**Team:**
- Eric — Lead (architecture & review)
- Quentin — AI Dev (Python/PyTorch/MediaPipe)
- Renaud — Backend Dev (Go/Gin)
- Romaric — Mobile Dev (Flutter)
- Arthur — DevOps (Docker/CI)
- Alexandra — Infra (RabbitMQ/PostgreSQL/MinIO)
- Darius — Docs
- Ridjan — Tester (tests unitaires & intégration)

## Learnings
