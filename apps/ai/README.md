:::warning
**Version:** 1.0
:::

---

# Ascension AI worker

Python worker of the Ascension monorepo. It turns a climbing video into a 2D analysis (skeleton, joint angles, metrics, movements) and then into coaching hints written by an LLM.

The worker consumes jobs from RabbitMQ, downloads the video from RustFS (S3), writes its progress and results into PostgreSQL, and publishes statuses back on RabbitMQ. Each pipeline step is also a command line sub-command, so it can run without any infrastructure.

This README describes the code as it is today. The wider pipeline (hold detection, pathfinding, Ghost Mode, 3D) is not implemented: see [pipeline-2d-decomposition.md](../../docs/Ascension/developer/apps/ai/pipeline-2d-decomposition.md).

---

## Table of Contents

- [Pipeline](#pipeline)
- [Installation](#installation)
- [Environment variables](#environment-variables)
- [Running the worker](#running-the-worker)
- [Command line steps](#command-line-steps)
- [Triggering a job by hand](#triggering-a-job-by-hand)
- [Tests](#tests)
- [Project layout](#project-layout)
- [Shared schemas](#shared-schemas)
- [Known limits](#known-limits)

---

## Pipeline

```mermaid
flowchart LR
    Producer["Go server or producer.py"] -->|"pose.detect.requested"| Detect["queue poses.detect"]
    Detect --> S3["RustFS"]
    Detect --> Steps["_1_mediapipe"]
    Steps --> DB[("analyses")]
    Steps -->|"pose.detect.completed"| Advice["queue poses.advice"]
    Manual["Manual rerun"] -->|"pose.advice.requested"| Advice
    Advice --> LLM["_2_advice + LLM"]
    LLM --> DB
    Detect -.->|"pose.detect.status"| Events["Status consumers"]
    Advice -.->|"pose.advice.status"| Events
```

_Summary: the detect job downloads the video, computes the result and stores it in PostgreSQL, then triggers the advice job. The advice job reads the result back, stores the hints and finishes the analysis. Both publish their statuses._

| Item           | Value                                                                                                                              |
| -------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| Exchange       | `events` (topic, durable)                                                                                                          |
| Queues         | `poses.detect`, `poses.advice`, plus a dead-letter queue `<queue>.dlq` bound to the exchange `events.dlx`                          |
| Consumed keys  | `pose.detect.requested` (payload `{job_id, object_key}`), `pose.detect.completed` and `pose.advice.requested` (payload `{job_id}`) |
| Published keys | `pose.detect.completed`, `pose.detect.status`, `pose.advice.status`                                                                |
| Statuses       | `pending`, `started`, `running`, `success`, `failed` (messages and the `analyses.status` column)                                   |
| Concurrency    | One job at a time per process. Scale by adding replicas                                                                            |

Job lifecycle in `analyses`:

| Step                | `status`  | `progress` |
| ------------------- | --------- | ---------- |
| Job taken           | `started` | 0          |
| Skeleton extraction | `running` | 5 to 70    |
| Movements computed  | `running` | 80         |
| `result` stored     | `running` | 85         |
| Advice generation   | `running` | 90         |
| Done                | `success` | 100        |

`success` is written only after the advice step. If the LLM fails or is not configured, the analysis still ends in `success` with `hints = NULL`, and `pose.advice.status` is `failed`. The advice step can be rerun with `pose.advice.requested`.

Temporary errors (storage, database, LLM) are retried three times with an in-memory backoff (2 s, then 4 s). After that, or on a permanent error (invalid payload, unreadable video), the job is published as `failed` and the message goes to `<queue>.dlq`. Error messages stored in the database and in statuses are short; the traceback stays in the logs.

---

## Installation

Requirements: Python 3.11, [uv](https://docs.astral.sh/uv/), [moon](https://moonrepo.dev) for the monorepo tasks, and Docker for the infrastructure (PostgreSQL, RabbitMQ, RustFS).

```bash
# From the repository root
moon run ai:install   # uv sync
moon run ai:setup     # downloads resources/pose_landmarker_full.task if missing

# Or by hand
cd apps/ai
uv sync
bash scripts/download-model.sh
```

If `import cv2` fails with `has no attribute 'VideoCapture'`, run `uv sync --reinstall-package opencv-contrib-python`.

---

## Environment variables

The worker reads the `.env` file at the repository root (copy `.env.example`). Docker Compose passes it to the `ai-worker` container.

| Variable                                                                              | Default                                                    | Role                                                                                             |
| ------------------------------------------------------------------------------------- | ---------------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| `POSTGRES_DB_URL`                                                                     | none                                                       | Full database URL. When unset, the URL is built from the `POSTGRES_*` variables below            |
| `POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB` | `localhost`, `5432`, `ascension`, `ascension`, `ascension` | Database connection                                                                              |
| `RABBITMQ_HOST`, `RABBITMQ_PORT`                                                      | `localhost`, `5672`                                        | Broker address                                                                                   |
| `RABBITMQ_USER`, `RABBITMQ_PASS`                                                      | none                                                       | Broker credentials. `RABBITMQ_DEFAULT_USER` and `RABBITMQ_DEFAULT_PASS` take precedence when set |
| `RABBITMQ_RETRY_DELAY`, `RABBITMQ_MAX_RETRIES`                                        | `5`, `12`                                                  | Connection retries at startup (seconds, count)                                                   |
| `RUSTFS_ENDPOINT`                                                                     | `http://localhost:9000`                                    | S3 endpoint                                                                                      |
| `RUSTFS_ACCESS_KEY`, `RUSTFS_SECRET_KEY`                                              | `ascension`, `ascension`                                   | S3 credentials                                                                                   |
| `RUSTFS_BUCKET`                                                                       | `videos`                                                   | Bucket that holds the videos. The worker never creates it                                        |
| `LLM_BASE_URL`                                                                        | none                                                       | Base URL of any OpenAI-compatible API                                                            |
| `LLM_API_KEY`                                                                         | empty                                                      | API key (optional for a local server)                                                            |
| `LLM_MODEL`                                                                           | none                                                       | Model name                                                                                       |
| `POSE_MODEL_PATH`                                                                     | `resources/pose_landmarker_full.task`                      | MediaPipe model, relative to `apps/ai`                                                           |
| `TEST_POSTGRES_URL`                                                                   | none                                                       | Database used by the integration and end-to-end tests. See [Tests](#tests)                       |

Without `LLM_BASE_URL` or `LLM_MODEL` the worker still starts: analyses end in `success` without hints.

To change the model, change only the three `LLM_*` variables. There is one client for every provider.

| Provider | `LLM_BASE_URL`                                             | `LLM_MODEL`             |
| -------- | ---------------------------------------------------------- | ----------------------- |
| Gemini   | `https://generativelanguage.googleapis.com/v1beta/openai/` | `gemini-3.1-flash-lite` |
| DeepSeek | `https://api.deepseek.com`                                 | `deepseek-flash`        |

> **Not tested with a real provider.** Every test uses a simulated client. The values above come from the providers' documentation and the model names must be checked against their catalogue. Gemini's page for the OpenAI-compatible API does not mention `response_format={"type": "json_object"}`: confirm it with a real key. Choosing a provider also has GDPR consequences: biomechanical data (no identifier, no video) leaves for a third party.

`GEMINI_API_KEY` and `GEMINI_MODEL` stay in `.env.example` because the scripts in `.github/scripts` (commit message and PR review tooling) still read them. The worker does not.

The Go server still reads the `MINIO_*` variable names. Their values must stay equal to the `RUSTFS_*` ones.

---

## Running the worker

Start the infrastructure, apply the migrations, then run the worker.

```bash
moon run root:db-up        # PostgreSQL, RabbitMQ and RustFS
moon run server:migrate    # includes the job_status and hints migrations
moon run ai:dev            # uv run worker, loads .env
```

Equivalent without moon: `cd apps/ai && uv run worker`.

Without a sub-command the worker connects to PostgreSQL, RustFS and RabbitMQ, then blocks on consumption. It exits with code 1 and a short message when a connection fails. The migrations must be applied first.

The bucket `videos` must exist. The Go server creates it at startup; `producer.py seed` creates it too.

Queues created by an older version have no dead-letter arguments and are refused by RabbitMQ (`PRECONDITION_FAILED`). Delete `poses.detect` and `poses.advice` in the management interface, without touching the volumes. The worker recreates them.

---

## Command line steps

Every step runs on its own: no RabbitMQ, no database, no storage. The output of each step is validated against `AnalysisResult` before it is written.

| Command                        | Input                | Output                                       | Main options (defaults)                                                                                           |
| ------------------------------ | -------------------- | -------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| `uv run worker pose-skeleton`  | `--video`            | `--out` raw skeleton JSON                    | `--render` writes a video with the skeleton drawn                                                                 |
| `uv run worker pose-filter`    | `--input`            | `--out` filtered JSON                        | `--min-visibility` (0.5), `--max-gap` (5 frames), `--window` (5 frames)                                           |
| `uv run worker pose-metrics`   | `--input`            | `--out` JSON with speeds and metrics         | `--bent-arm` (0.8)                                                                                                |
| `uv run worker pose-movements` | `--input`            | `--out` JSON with movements and pauses       | `--move-speed` (0.8), `--stop-speed` (0.4), `--merge-gap` (150 ms), `--min-move` (100 ms), `--min-pause` (500 ms) |
| `uv run worker pose-detect`    | `--video`            | `--out` full result (all four steps chained) | `--render`                                                                                                        |
| `uv run worker pose-advice`    | `--input` (a result) | `--out` hints JSON                           | `--dry-run` writes the prompt only (no key, no network), `--model`, `--base-url`                                  |

Speeds are in torso lengths per second.

```bash
cd apps/ai
uv run worker pose-detect --video resources/example-2.mp4 --out /tmp/result.json
uv run worker pose-advice --input /tmp/result.json --out /tmp/prompt.txt --dry-run

# Or chain the steps one by one
uv run worker pose-skeleton  --video resources/example-2.mp4 --out /tmp/skeleton.json
uv run worker pose-filter    --input /tmp/skeleton.json --out /tmp/filtered.json
uv run worker pose-metrics   --input /tmp/filtered.json --out /tmp/metrics.json
uv run worker pose-movements --input /tmp/metrics.json --out /tmp/movements.json
```

The same task exists in moon: `moon run ai:pose-detect -- --video resources/example-2.mp4 --out /tmp/result.json`.

The thresholds are named constants in `src/worker/_1_mediapipe/` and can be overridden on the command line. See [Known limits](#known-limits) before trusting them.

---

## Triggering a job by hand

Until the Go server publishes on these queues (see the backend handoff note, which is not versioned in the repository), `src/producer.py` plays the server. It needs PostgreSQL (migrated), RabbitMQ and RustFS.

| Command                                                                 | Effect                                                                                                                                  |
| ----------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| `uv run python src/producer.py seed --video resources/example-2.mp4`    | Creates a test user, video and `pending` analysis, creates the bucket if missing, uploads the video, prints `job_id=` and `object_key=` |
| `uv run python src/producer.py detect --job-id <id> --object-key <key>` | Publishes `pose.detect.requested`                                                                                                       |
| `uv run python src/producer.py advice --job-id <id>`                    | Publishes `pose.advice.requested` (rerun of the advice step)                                                                            |

Through moon: `moon run ai:producer -- seed --video resources/example-2.mp4`.

---

## Tests

| Command                | Scope                                                                                                                                  | Needs                                 |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------- |
| `moon run ai:test`     | Unit tests plus functional tests (the CLI in sub-processes on `resources/example-2.mp4`). `-m "not e2e and not integration"`           | No infrastructure, no network         |
| `moon run ai:coverage` | Same tests with a coverage report of `src/` (generated `shared/models.py` excluded)                                                    | No infrastructure                     |
| `moon run ai:e2e`      | End to end (real worker, RabbitMQ, PostgreSQL, RustFS, LLM simulated) plus the PostgreSQL integration tests. `-m "e2e or integration"` | PostgreSQL migrated, RabbitMQ, RustFS |

`ai:test` is no longer tolerant: a failing test fails the task and the CI. It also depends on `ai:setup` (model download) and `root:schemas-generate`.

`ai:e2e` depends on `root:db-up` and `server:migrate` (the `migrate` tool comes from `moon run server:setup`). A test whose service is unreachable is skipped, not failed: read the reasons with `-rs`.

**`TEST_POSTGRES_URL`** points the integration and end-to-end tests to a specific database. When unset, the end-to-end test falls back to `POSTGRES_DB_URL` or the `POSTGRES_*` variables, which target port 5432 by default. If another project uses that port, the test would connect to it with `ascension/ascension`. Always set the variable (or `POSTGRES_PORT`) to a disposable, migrated database. The integration tests are skipped without `TEST_POSTGRES_URL`.

Example with disposable containers (adapt the ports):

```bash
export TEST_POSTGRES_URL=postgres://ascension:ascension@127.0.0.1:55434/ascension \
       POSTGRES_PORT=55434 RABBITMQ_PORT=55672 RUSTFS_ENDPOINT=http://127.0.0.1:59000
cd apps/ai && uv run pytest -p no:cacheprovider -rs -m "e2e or integration"
```

Where the tests live:

| Path                | Content                                                                                            |
| ------------------- | -------------------------------------------------------------------------------------------------- |
| `tests/test_*.py`   | Unit tests with simulated broker, database, storage and LLM                                        |
| `tests/functional/` | The `worker` CLI in sub-processes                                                                  |
| `tests/e2e/`        | Real services, five scenarios: nominal, invalid payload, missing object, LLM failure, advice rerun |

Without `--upstream none`, moon first runs the upstream tasks, including `root:schemas-generate`, which rewrites `src/shared/models.py` and `apps/server/internal/shared/models.go`.

---

## Project layout

| Path (under `apps/ai/`)            | Role                                                                                                                                   |
| ---------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| `src/worker/__init__.py`, `cli.py` | `worker` entry point and sub-commands                                                                                                  |
| `src/worker/runtime.py`            | Lazy, cached access to the broker, database, storage, skeleton extractor and LLM                                                       |
| `src/worker/_1_mediapipe/`         | Pipeline steps: `pose_skeleton`, `pose_filter`, `pose_metrics`, `pose_movements`, plus `pose_geometry` and `pose_detect` (chains them) |
| `src/worker/_2_advice/`            | `pose_advice`: prompt, LLM call, `Hints`                                                                                               |
| `src/worker/handlers/`             | One handler per RabbitMQ flow, plus `failure.py`                                                                                       |
| `src/services/`                    | Third-party services: `rabbitmq.py`, `postgresql.py`, `rustfs.py`, `llm.py`                                                            |
| `src/common/models/`               | Configuration models of the services                                                                                                   |
| `src/common/db_schemas/`           | Row model of the `analyses` table                                                                                                      |
| `src/common/utils/`                | Retry and error classes, the `@consume` wrapper, bindings, logger                                                                      |
| `src/shared/models.py`             | Generated from `schemas/`. Never edit it                                                                                               |
| `src/producer.py`                  | Stand-in for the Go server                                                                                                             |
| `scripts/download-model.sh`        | Downloads the MediaPipe model                                                                                                          |
| `resources/`                       | Model and the sample video `example-2.mp4`                                                                                             |
| `tests/`                           | See [Tests](#tests)                                                                                                                    |

Pipeline steps take and return data. They do not depend on RabbitMQ, the database or storage.

---

## Shared schemas

The contract between the worker and the server lives in `schemas/` at the repository root. `moon run root:schemas-generate` generates `src/shared/models.py` (Python) and `apps/server/internal/shared/models.go` (Go). Edit the schemas, never the generated files. `ai:lint`, `ai:test` and `ai:build` run the generation first.

---

## Known limits

- **Hands are unreliable on `example-2.mp4`.** With `MIN_VISIBILITY` at 0.5, the wrist is measured on only 142 (left) and 136 (right) frames out of 309. On that video no frame has both arms measurable at once. The movements of the hands are therefore unusable and no pause is detected (14 movements, 0 pause). The feet are consistent. Lowering `MIN_VISIBILITY` to 0.1 to 0.3 makes the hands continuous, but it is not validated: those landmarks are ones the model judges unreliable. The advice step flags such limbs as unreliable and forbids conclusions on them.
- **Thresholds are calibrated on one video** (`resources/example-2.mp4`, climber seen from behind): `MIN_VISIBILITY` 0.5, `MAX_GAP_FRAMES` 5, `SMOOTH_WINDOW` 5, `BENT_ARM_THRESHOLD` 0.8, speeds 0.8 and 0.4 torso lengths per second, merge gap 150 ms, minimum movement 100 ms, minimum pause 500 ms. Revisit them with real climbs and other camera angles.
- **LLM providers are not tested for real.** No call to Gemini or DeepSeek has been made. Model names and JSON mode support are unverified.
- **The Go server is not wired to the worker.** It still publishes on `vision.skeleton`, which nobody consumes, and still uses the old status values. Only `producer.py` triggers jobs. The wiring to do on the Go side is described in the backend handoff note (not versioned in the repository).
- **`moon run root:db-up` is broken on a fresh machine.** `docker-compose.yml` has `build: ./apps/server/postgres` for the `postgresql` service and that folder does not exist. It works only where the image `ghcr.io/ascension-eip/ascension-postgres:latest` is already pulled. Port 5432 must also be free.
- **An invalid payload goes to the dead-letter queue without any status.** The analysis stays `pending` in the database. The server has to detect it (for example by watching `<queue>.dlq` or a timeout).
- **Progress 75 is never written.** Skeleton, filtering, metrics and movements run in one call, so the progress goes from 70 to 80.
- **`LOG_LEVEL` is ignored.** `moon run ai:dev` sets `LOG_LEVEL=debug`, but the logger is fixed at `INFO`, so the debug traceback of a failed command is not shown.
- **No reconnection.** If the RabbitMQ connection drops, the process exits with a non-zero code and Docker restarts it. The worker finishes the running job first.
- **The end-to-end test is not in the CI.** It needs `docker compose`. Processing time of `example-2.mp4` (10 s, 1.6 MB) was measured at about 6 s on a CPU, with a simulated LLM. This is a baseline from a single video.
