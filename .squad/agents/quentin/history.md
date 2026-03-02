# Quentin — History

## Project Context
**Ascension** — Climbing video analysis platform. AI Workers in Python (PyTorch, MediaPipe, OpenCV). Two pipelines: Vision (hold detection → skeleton → advice → ghost) and Training (program generation). Workers consume from RabbitMQ queues, read video from MinIO/S3, store results in PostgreSQL. User: Gianni TUERO.

## Learnings
- **consumer.py is the single entry point** — Dockerfile CMD runs `python consumer.py`. All pipeline routing will go through this file.
- **Worker pattern**: RabbitMQ connection with retry loop (12 attempts × 5s), single queue consumption with `prefetch_count=1`, temp file cleanup in `finally` block.
- **S3 URL format**: Jobs use `s3://bucket/key` for `video_url`. Parsed with `urllib.parse.urlparse`.
- **DB pattern**: `analyses` table updated via `UPDATE ... SET status, result_json, processing_time_ms, completed_at WHERE id = analysis_id`. Status transitions: → `completed` or → `failed`.
- **Event publishing**: Topic exchange `ascension.events`, routing key `skeleton.completed.{job_id}`.
- **pose_analysis.py** is the clean wrapper around MediaPipe. Exposes `analyze(video_path) -> dict` with `{"frames": [...]}`. Do NOT use `mediapipe.py` directly.
- **pyproject.toml py-modules**: Must list all top-level modules (`consumer`, `main`, `pose_analysis`) for setuptools to package them.
- **docker-compose.yml env vars**: ai-worker now receives MinIO (`MINIO_ENDPOINT`, `MINIO_ROOT_USER`, `MINIO_ROOT_PASSWORD`) and Postgres (`POSTGRES_HOST`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`, `DB_URI`) vars. (Updated by Quentin 2026-03-02)

