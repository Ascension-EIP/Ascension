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

- **LANDMARKS dict étendu à 33 points** — Le dict `LANDMARKS` dans `pose_analysis.py` ne contenait que 12 landmarks (épaules, coudes, poignets, hanches, genoux, chevilles). Remplacé par la liste complète des 33 landmarks MediaPipe Pose (nez, yeux, oreilles, bouche, épaules, coudes, poignets, doigts, hanches, genoux, chevilles, talons, orteils). (2026-03-02, demandé par Gianni)
- **Docstring corrigée** — La docstring du module référençait encore l'ancien nom `mediapipe_utils.py`. Corrigé en `pose_analysis.py`. (2026-03-02)
- **Variable de boucle `l` renommée en `lnd`** — Dans `_process_pose`, la variable `l` était visuellement ambiguë avec le chiffre `1`. Renommée en `lnd` dans toutes ses occurrences. (2026-03-02)

- **Docs AI alignées sur le workflow conda de `apps/ai/moon.yml`** — Les guides docs utilisent désormais explicitement `environment.yml` + `conda run --name ascension-ai ...` et les tâches moon `ai:setup/install/dev/lint/test/build`. À garder comme source de vérité pour l'onboarding. (2026-03-03)
- **Runtime deps du worker doivent vivre dans `pyproject.toml`** — `consumer.py` importe `boto3`, `pika` et `psycopg2`; ces paquets doivent être déclarés dans `[project.dependencies]` pour que `moon run ai:install` (`pip install -e .[dev]` dans l'env conda) rende `moon run ai:dev` exécutable sur setup frais. (2026-03-03, demandé par Gianni)

- **PR #70 (review-only) : conda setup encore partiellement non déterministe** — `environment.yml` ne contient que `python` + `pip` (pas de lock des deps runtime), `apps/ai/moon.yml` utilise une env par `--prefix ./ai-env` alors que la doc référence `--name ascension-ai`, et `pyproject.toml` pinne `opencv-python` + `opencv-contrib-python` en parallèle (risque de conflit de wheels). Point remonté en review PR avec recommandation d'aligner le flow et verrouiller les dépendances. (2026-03-03, PR #70)
