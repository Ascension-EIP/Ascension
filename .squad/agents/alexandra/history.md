# Alexandra — History

## Project Context
**Ascension** — Climbing video analysis platform. Infrastructure services: RabbitMQ (3 exchanges, 5 queues with DLQ), PostgreSQL (users, videos, analyses, metrics), MinIO/S3 (video storage with lifecycle policies). All services in Docker Compose. User: Gianni TUERO.

## Learnings
- **docker-compose.yml env vars** (2026-03-02): ai-worker service now receives MinIO endpoint, credentials, and PostgreSQL connection details from docker-compose environment variables (`MINIO_ENDPOINT`, `MINIO_ROOT_USER`, `MINIO_ROOT_PASSWORD`, `POSTGRES_HOST`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`, `DB_URI`). Enables consumer.py to connect to all required services at startup.

