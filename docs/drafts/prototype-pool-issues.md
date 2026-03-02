> **Last updated:** 2nd March 2026
> **Version:** 1.0
> **Authors:** Nicolas TORO
> **Status:** Draft

---

# Prototype Pool — GitHub Issues Draft

Ce document liste toutes les issues GitHub proposées pour la piscine de prototype (sprint de 2 semaines).
Chaque issue suit le format `SCOPE: short-description` et contient une description + définitions of done.
Les issues sont organisées en **issues parentes** (epics) et **issues enfants** (tâches atomiques).

> **Convention de labels suggérés :** `epic`, `backend`, `ai`, `mobile`, `infra`, `docs`
> **Milestones suggérées :** `Definition`, `Sprint`, `Demo Checkpoint`, `Finalization`, `Presentation`

---

## Table of Contents

- [Issues Parentes (Epics)](#issues-parentes-epics)
  - [EPIC-1 — Infrastructure & Docker Setup](#epic-1--infrastructure--docker-setup)
  - [EPIC-2 — Backend: Rust/Axum Server](#epic-2--backend-rustaxum-server)
  - [EPIC-3 — AI: MediaPipe Pipeline](#epic-3--ai-mediapipe-pipeline)
  - [EPIC-4 — Mobile: Flutter Application](#epic-4--mobile-flutter-application)
  - [EPIC-5 — RabbitMQ Integration](#epic-5--rabbitmq-integration)
  - [EPIC-6 — End-to-End Integration](#epic-6--end-to-end-integration)
- [Issues Enfants Détaillées](#issues-enfants-détaillées)

---

## Issues Parentes (Epics)

---

### EPIC-1 — Infrastructure & Docker Setup

#### 📌 Issue parente

**Titre :** `INFRA: set up local development infrastructure with Docker Compose`

**Labels :** `epic`, `infra`
**Milestone :** `Definition`
**Assignee :** Nicolas TORO

**Description :**
```
Set up the complete local development infrastructure using Docker Compose, including all required services for the prototype sprint.

## Goal
Provide a fully functional local environment that any team member can spin up with a single command, enabling all services (PostgreSQL, RabbitMQ, MinIO) to communicate correctly.

## Scope
- Docker Compose configuration for all infrastructure services
- PostgreSQL database with initial schema
- RabbitMQ message broker with management UI
- MinIO object storage with initial bucket configuration
- Environment variable management (.env.example)

## Definition of Done
- [ ] `docker compose up -d` starts all services without errors
- [ ] PostgreSQL is accessible on port `5432` with the correct credentials
- [ ] RabbitMQ management UI is accessible on port `15672`
- [ ] MinIO console is accessible on port `9001`
- [ ] `.env.example` contains all required variables with documentation
- [ ] All services pass a basic health check
- [ ] README section updated with local setup instructions

## Related Issues
- #INFRA-1 Docker Compose base configuration
- #INFRA-2 PostgreSQL setup & initial schema
- #INFRA-3 RabbitMQ setup & queue declaration
- #INFRA-4 MinIO setup & bucket initialization
```

**Commande gh :**
```bash
gh issue create \
  --title "INFRA: set up local development infrastructure with Docker Compose" \
  --label "epic,infra" \
  --milestone "Definition" \
  --assignee "@me" \
  --body "Set up the complete local development infrastructure using Docker Compose, including all required services for the prototype sprint.

## Goal
Provide a fully functional local environment that any team member can spin up with a single command.

## Definition of Done
- [ ] \`docker compose up -d\` starts all services without errors
- [ ] PostgreSQL is accessible on port \`5432\` with the correct credentials
- [ ] RabbitMQ management UI is accessible on port \`15672\`
- [ ] MinIO console is accessible on port \`9001\`
- [ ] \`.env.example\` contains all required variables
- [ ] All services pass a basic health check
- [ ] README updated with local setup instructions"
```

---

### EPIC-2 — Backend: Rust/Axum Server

#### 📌 Issue parente

**Titre :** `SERVER: initialize Rust/Axum backend with core routes`

**Labels :** `epic`, `backend`
**Milestone :** `Sprint`
**Assignee :** Lou PELLEGRINO

**Description :**
```
Initialize the Rust/Axum backend server with the foundational routes required for the prototype end-to-end flow.

## Goal
A working Rust API that can handle video upload requests (presigned URL generation), trigger analysis jobs, and return results fetched from PostgreSQL.

## Scope
- Project initialization with Axum, Tokio, SQLx
- PostgreSQL connection pool
- Routes: presigned URL, trigger analysis, fetch result
- RabbitMQ publisher integration
- Error handling and basic logging

## Definition of Done
- [ ] Server starts with `moon run server:dev`
- [ ] `POST /api/v1/analysis/video/request-upload` returns a valid presigned MinIO URL
- [ ] `POST /api/v1/analysis/video/start` publishes a message to RabbitMQ
- [ ] `GET /api/v1/analysis/video/:id` returns the analysis result from PostgreSQL
- [ ] PostgreSQL connection pool is initialized and functional
- [ ] All routes return proper HTTP status codes and JSON responses
- [ ] Basic error handling is in place (no panics on bad input)

## Related Issues
- #SERVER-1 Project init & dependencies
- #SERVER-2 PostgreSQL connection pool
- #SERVER-3 Route: presigned upload URL
- #SERVER-4 Route: trigger analysis
- #SERVER-5 Route: fetch analysis result
- #SERVER-6 RabbitMQ publisher
```

**Commande gh :**
```bash
gh issue create \
  --title "SERVER: initialize Rust/Axum backend with core routes" \
  --label "epic,backend" \
  --milestone "Sprint" \
  --assignee "Lou PELLEGRINO" \
  --body "Initialize the Rust/Axum backend server with the foundational routes required for the prototype end-to-end flow.

## Definition of Done
- [ ] Server starts with \`moon run server:dev\`
- [ ] \`POST /api/v1/analysis/video/request-upload\` returns a valid presigned MinIO URL
- [ ] \`POST /api/v1/analysis/video/start\` publishes a message to RabbitMQ
- [ ] \`GET /api/v1/analysis/video/:id\` returns the analysis result from PostgreSQL
- [ ] PostgreSQL connection pool is initialized and functional
- [ ] All routes return proper HTTP status codes and JSON responses
- [ ] Basic error handling is in place (no panics on bad input)"
```

---

### EPIC-3 — AI: MediaPipe Pipeline

#### 📌 Issue parente

**Titre :** `AI: implement MediaPipe pose estimation pipeline`

**Labels :** `epic`, `ai`
**Milestone :** `Sprint`
**Assignee :** Olivier POUECH

**Description :**
```
Implement the first AI pipeline using MediaPipe for pose estimation on climbing videos. The worker consumes analysis jobs from RabbitMQ and publishes structured JSON results back.

## Goal
A working Python AI worker that can analyze a climbing video, extract 33 skeleton keypoints via MediaPipe, compute basic joint angles, and return a structured JSON result.

## Scope
- MediaPipe Pose setup and video processing with OpenCV
- Keypoint extraction (33 landmarks)
- Basic angle computation (elbow, knee, hip)
- RabbitMQ consumer/publisher with pika
- Result stored via backend or published directly

## Definition of Done
- [ ] Worker starts with `moon run ai:dev`
- [ ] Worker successfully consumes a job from the RabbitMQ queue
- [ ] MediaPipe extracts 33 keypoints from each video frame
- [ ] Joint angles are computed and included in the result
- [ ] Result is a valid JSON with structure: `{ keypoints: [...], angles: {...}, feedback: [...] }`
- [ ] Result is published back to RabbitMQ or stored via API
- [ ] Worker handles missing/corrupt video files gracefully

## Related Issues
- #AI-1 MediaPipe setup & video frame extraction
- #AI-2 Keypoint extraction & angle computation
- #AI-3 JSON result structure & serialization
- #AI-4 RabbitMQ consumer setup
- #AI-5 RabbitMQ result publisher
```

**Commande gh :**
```bash
gh issue create \
  --title "AI: implement MediaPipe pose estimation pipeline" \
  --label "epic,ai" \
  --milestone "Sprint" \
  --assignee "Olivier POUECH" \
  --body "Implement the first AI pipeline using MediaPipe for pose estimation on climbing videos.

## Definition of Done
- [ ] Worker starts with \`moon run ai:dev\`
- [ ] Worker successfully consumes a job from the RabbitMQ queue
- [ ] MediaPipe extracts 33 keypoints from each video frame
- [ ] Joint angles are computed and included in the result
- [ ] Result is a valid JSON with structure: \`{ keypoints: [...], angles: {...}, feedback: [...] }\`
- [ ] Result is published back to RabbitMQ
- [ ] Worker handles missing/corrupt video files gracefully"
```

---

### EPIC-4 — Mobile: Flutter Application

#### 📌 Issue parente

**Titre :** `MOBILE: build Flutter UI for video upload and analysis display`

**Labels :** `epic`, `mobile`
**Milestone :** `Sprint`
**Assignee :** Christophe VANDEVOIR

**Description :**
```
Build the Flutter mobile application that allows users to select a video, upload it to MinIO via a presigned URL, trigger an analysis, and display the result.

## Goal
A seamless, continuous user flow — from video selection to skeleton overlay display — without isolated/disconnected screens.

## Scope
- Video picker integration
- HTTP client for backend communication
- Direct video upload to MinIO via presigned URL
- Analysis trigger and status polling
- Result display with basic skeleton overlay or keypoint data

## Definition of Done
- [ ] App builds and runs with `moon run mobile:dev` on Android and iOS
- [ ] User can select a video from the device gallery
- [ ] App requests a presigned URL from the backend and uploads the video directly to MinIO
- [ ] "Analyse" button triggers the analysis request to the backend
- [ ] App polls or receives the analysis result
- [ ] Result is displayed (at minimum as raw JSON; ideally as a basic overlay)
- [ ] The flow is continuous — no dead-ends or isolated screens

## Related Issues
- #MOBILE-1 Project setup & dependencies
- #MOBILE-2 Video picker & local video handling
- #MOBILE-3 Backend HTTP client service
- #MOBILE-4 Video upload flow (presigned URL)
- #MOBILE-5 Analysis trigger & status polling
- #MOBILE-6 Result display screen
```

**Commande gh :**
```bash
gh issue create \
  --title "MOBILE: build Flutter UI for video upload and analysis display" \
  --label "epic,mobile" \
  --milestone "Sprint" \
  --assignee "Christophe VANDEVOIR" \
  --body "Build the Flutter mobile application that allows users to select a video, upload it to MinIO via a presigned URL, trigger an analysis, and display the result.

## Definition of Done
- [ ] App builds and runs with \`moon run mobile:dev\`
- [ ] User can select a video from the device gallery
- [ ] App requests a presigned URL and uploads the video directly to MinIO
- [ ] 'Analyse' button triggers the analysis request to the backend
- [ ] App polls or receives the analysis result
- [ ] Result is displayed (at minimum as raw JSON; ideally as a basic overlay)
- [ ] The flow is continuous — no dead-ends or isolated screens"
```

---

### EPIC-5 — RabbitMQ Integration

#### 📌 Issue parente

**Titre :** `BROKER: implement RabbitMQ message flow between server and AI worker`

**Labels :** `epic`, `backend`, `ai`
**Milestone :** `Sprint`
**Assignee :** Gianni TUERO

**Description :**
```
Implement the full RabbitMQ message flow: the backend publishes analysis jobs, the AI worker consumes them, processes the video, and publishes the result back for the backend to consume.

## Goal
A reliable, bidirectional message flow between the Rust backend and Python AI worker via RabbitMQ, ensuring no job is ever lost.

## Scope
- Queue declaration: `analysis_jobs` (backend → AI) and `analysis_results` (AI → backend)
- Backend publisher (lapin crate in Rust)
- AI worker consumer (pika in Python)
- AI worker publisher for results
- Backend consumer for results
- Message schema definition

## Definition of Done
- [ ] `analysis_jobs` queue is declared and persistent
- [ ] `analysis_results` queue is declared and persistent
- [ ] Backend successfully publishes an analysis job message with correct schema
- [ ] AI worker consumes the message and logs receipt
- [ ] AI worker publishes a result message to `analysis_results`
- [ ] Backend consumes the result and stores it in PostgreSQL
- [ ] Messages are acknowledged (ACK) after successful processing
- [ ] Message schema is documented

## Related Issues
- #BROKER-1 Queue declaration & configuration
- #BROKER-2 Backend publisher (Rust/lapin)
- #BROKER-3 AI worker consumer (Python/pika)
- #BROKER-4 AI worker result publisher
- #BROKER-5 Backend result consumer
```

**Commande gh :**
```bash
gh issue create \
  --title "BROKER: implement RabbitMQ message flow between server and AI worker" \
  --label "epic,backend,ai" \
  --milestone "Sprint" \
  --assignee "Gianni TUERO" \
  --body "Implement the full RabbitMQ message flow between the Rust backend and Python AI worker.

## Definition of Done
- [ ] \`analysis_jobs\` queue is declared and persistent
- [ ] \`analysis_results\` queue is declared and persistent
- [ ] Backend successfully publishes an analysis job message
- [ ] AI worker consumes the message
- [ ] AI worker publishes a result to \`analysis_results\`
- [ ] Backend consumes the result and stores it in PostgreSQL
- [ ] Messages are ACKed after successful processing
- [ ] Message schema is documented"
```

---

### EPIC-6 — End-to-End Integration

#### 📌 Issue parente

**Titre :** `E2E: validate full end-to-end user journey (upload → analysis → result)`

**Labels :** `epic`, `backend`, `ai`, `mobile`, `infra`
**Milestone :** `Demo Checkpoint`
**Assignee :** Nicolas TORO

**Description :**
```
Validate and demonstrate the complete end-to-end user journey as defined in the prototype scope.

## Goal
The full flow must work seamlessly: mobile app → backend → MinIO → RabbitMQ → AI worker → PostgreSQL → mobile app.

## User Journey to Validate
1. Mobile app requests a presigned URL → backend returns it
2. Mobile app uploads video directly to MinIO
3. User taps "Analyse" → backend publishes job to RabbitMQ
4. AI worker consumes job, fetches video from MinIO, runs MediaPipe
5. AI worker publishes JSON result to RabbitMQ
6. Backend consumes result, stores in PostgreSQL
7. Mobile app retrieves and displays result

## Definition of Done
- [ ] All 7 steps of the user journey complete without manual intervention
- [ ] End-to-end flow demonstrated with a real climbing video on a physical device
- [ ] No service crashes during the demo flow
- [ ] Result displayed on mobile app (keypoints or basic overlay)
- [ ] All inter-service communication is logged and traceable

## Related Issues
- #E2E-1 Integration smoke test
- #E2E-2 Demo preparation & test video
```

**Commande gh :**
```bash
gh issue create \
  --title "E2E: validate full end-to-end user journey (upload → analysis → result)" \
  --label "epic,backend,ai,mobile,infra" \
  --milestone "Demo Checkpoint" \
  --assignee "@me" \
  --body "Validate and demonstrate the complete end-to-end user journey as defined in the prototype scope.

## User Journey to Validate
1. Mobile app requests a presigned URL → backend returns it
2. Mobile app uploads video directly to MinIO
3. User taps 'Analyse' → backend publishes job to RabbitMQ
4. AI worker consumes job, fetches video from MinIO, runs MediaPipe
5. AI worker publishes JSON result to RabbitMQ
6. Backend consumes result, stores in PostgreSQL
7. Mobile app retrieves and displays result

## Definition of Done
- [ ] All 7 steps complete without manual intervention
- [ ] Flow demonstrated with a real climbing video on a physical device
- [ ] No service crashes during the demo flow
- [ ] Result displayed on mobile app
- [ ] All inter-service communication is logged"
```

---

## Issues Enfants Détaillées

---

### 🔵 INFRA — Issues Enfants

---

#### INFRA-1

**Titre :** `INFRA: create base Docker Compose configuration for all services`

**Labels :** `infra`
**Milestone :** `Definition`
**Assignee :** Nicolas TORO
**Parent :** EPIC-1

**Description :**
```
Create the base `docker-compose.yml` at the root of the monorepo, defining all required services for local development: PostgreSQL, RabbitMQ, and MinIO.

## Definition of Done
- [ ] `docker-compose.yml` defines services: `postgres`, `rabbitmq`, `minio`
- [ ] Each service uses a named volume for data persistence
- [ ] Services are connected via a shared Docker network (`ascension-net`)
- [ ] Ports are correctly mapped: `5432`, `5672`, `15672`, `9000`, `9001`
- [ ] Images are pinned to specific versions (no `latest` in production)
- [ ] `docker compose up -d` runs without errors on macOS, Arch Linux, and NixOS
```

**Commande gh :**
```bash
gh issue create \
  --title "INFRA: create base Docker Compose configuration for all services" \
  --label "infra" \
  --milestone "Definition" \
  --assignee "@me" \
  --body "Create the base \`docker-compose.yml\` at the root of the monorepo.

## Definition of Done
- [ ] \`docker-compose.yml\` defines services: \`postgres\`, \`rabbitmq\`, \`minio\`
- [ ] Each service uses a named volume for data persistence
- [ ] Services are on a shared Docker network (\`ascension-net\`)
- [ ] Ports mapped: \`5432\`, \`5672\`, \`15672\`, \`9000\`, \`9001\`
- [ ] \`docker compose up -d\` runs without errors on macOS, Arch Linux, and NixOS"
```

---

#### INFRA-2

**Titre :** `INFRA: set up PostgreSQL with initial database schema`

**Labels :** `infra`, `backend`
**Milestone :** `Definition`
**Assignee :** Lou PELLEGRINO
**Parent :** EPIC-1

**Description :**
```
Configure the PostgreSQL service in Docker Compose and apply the initial schema (migrations) for the prototype tables: `users`, `videos`, `analyses`.

## Definition of Done
- [ ] PostgreSQL container starts successfully via Docker Compose
- [ ] Initial SQL migration creates `users`, `videos`, and `analyses` tables
- [ ] Schema matches the specifications in `docs/developer_guide/architecture/specifications/database-schema.md`
- [ ] Migration script is idempotent (can be re-run safely)
- [ ] Database credentials are loaded from `.env`
- [ ] Connection can be verified with `psql` or a DB client (e.g., DBeaver)
```

**Commande gh :**
```bash
gh issue create \
  --title "INFRA: set up PostgreSQL with initial database schema" \
  --label "infra,backend" \
  --milestone "Definition" \
  --body "Configure PostgreSQL in Docker Compose and apply the initial schema for \`users\`, \`videos\`, and \`analyses\` tables.

## Definition of Done
- [ ] PostgreSQL container starts successfully
- [ ] Initial migration creates \`users\`, \`videos\`, \`analyses\` tables
- [ ] Schema matches the database spec document
- [ ] Migration is idempotent
- [ ] Credentials are loaded from \`.env\`
- [ ] Connection verified with a DB client"
```

---

#### INFRA-3

**Titre :** `INFRA: configure RabbitMQ with required queues and exchanges`

**Labels :** `infra`
**Milestone :** `Definition`
**Assignee :** Gianni TUERO
**Parent :** EPIC-1

**Description :**
```
Configure the RabbitMQ service in Docker Compose and declare the required queues and exchanges for the prototype message flow.

## Queues Required
- `analysis_jobs` — durable, consumed by the AI worker
- `analysis_results` — durable, consumed by the backend

## Definition of Done
- [ ] RabbitMQ container starts successfully via Docker Compose
- [ ] Management UI is accessible at `http://localhost:15672` (guest/guest)
- [ ] Queue `analysis_jobs` is declared as durable
- [ ] Queue `analysis_results` is declared as durable
- [ ] Queues survive a container restart (persistence confirmed)
- [ ] Credentials are loaded from `.env`
```

**Commande gh :**
```bash
gh issue create \
  --title "INFRA: configure RabbitMQ with required queues and exchanges" \
  --label "infra" \
  --milestone "Definition" \
  --body "Configure RabbitMQ in Docker Compose and declare the required queues for the prototype.

## Queues Required
- \`analysis_jobs\` — durable, consumed by AI worker
- \`analysis_results\` — durable, consumed by backend

## Definition of Done
- [ ] RabbitMQ container starts successfully
- [ ] Management UI accessible at \`http://localhost:15672\`
- [ ] Both queues declared as durable
- [ ] Queues survive a container restart
- [ ] Credentials loaded from \`.env\`"
```

---

#### INFRA-4

**Titre :** `INFRA: configure MinIO with initial bucket for video storage`

**Labels :** `infra`
**Milestone :** `Definition`
**Assignee :** Nicolas TORO
**Parent :** EPIC-1

**Description :**
```
Configure the MinIO service in Docker Compose and create the initial bucket used for video uploads during the prototype.

## Definition of Done
- [ ] MinIO container starts successfully via Docker Compose
- [ ] MinIO console is accessible at `http://localhost:9001`
- [ ] Bucket `ascension-videos` is created on first startup (via init script or env vars)
- [ ] Access key and secret key are loaded from `.env`
- [ ] Backend can generate a valid presigned PUT URL for the bucket
- [ ] A test file can be uploaded to the bucket via a presigned URL (manual test)
```

**Commande gh :**
```bash
gh issue create \
  --title "INFRA: configure MinIO with initial bucket for video storage" \
  --label "infra" \
  --milestone "Definition" \
  --body "Configure MinIO in Docker Compose and create the initial video storage bucket.

## Definition of Done
- [ ] MinIO container starts successfully
- [ ] Console accessible at \`http://localhost:9001\`
- [ ] Bucket \`ascension-videos\` created on startup
- [ ] Credentials loaded from \`.env\`
- [ ] Backend can generate a valid presigned PUT URL
- [ ] A test file can be uploaded via a presigned URL"
```

---

### 🟢 SERVER — Issues Enfants

---

#### SERVER-1

**Titre :** `SERVER: initialize Rust/Axum project structure and dependencies`

**Labels :** `backend`
**Milestone :** `Sprint`
**Assignee :** Lou PELLEGRINO
**Parent :** EPIC-2

**Description :**
```
Initialize the Rust backend project under `apps/server/` with all required dependencies, basic Axum server setup, and moon task configuration.

## Dependencies Required (Cargo.toml)
- `axum = "0.8.8"` — HTTP framework
- `tokio = { version = "1.49.0", features = ["full"] }` — async runtime
- `dotenv = "0.15.0"` — env var loading
- `sqlx` with PostgreSQL and UUID features — database access
- `lapin` — RabbitMQ AMQP client
- `serde / serde_json` — JSON serialization
- `tracing / tracing-subscriber` — structured logging
- `aws-sdk-s3` or `rusoto_s3` — MinIO presigned URL generation

## Definition of Done
- [ ] `Cargo.toml` contains all required dependencies with pinned versions
- [ ] `moon run server:dev` starts the server successfully
- [ ] Server listens on the configured port (from `.env`)
- [ ] `GET /health` returns `200 OK` with `{ "status": "ok" }`
- [ ] Structured logging is initialized with `tracing`
- [ ] `.env` variables are loaded on startup
```

**Commande gh :**
```bash
gh issue create \
  --title "SERVER: initialize Rust/Axum project structure and dependencies" \
  --label "backend" \
  --milestone "Sprint" \
  --body "Initialize the Rust backend project with all required dependencies and basic Axum server setup.

## Definition of Done
- [ ] \`Cargo.toml\` contains all required dependencies
- [ ] \`moon run server:dev\` starts the server
- [ ] Server listens on the configured port (from \`.env\`)
- [ ] \`GET /health\` returns \`200 OK\` with \`{ \"status\": \"ok\" }\`
- [ ] Structured logging initialized
- [ ] \`.env\` variables loaded on startup"
```

---

#### SERVER-2

**Titre :** `SERVER: set up PostgreSQL connection pool with SQLx`

**Labels :** `backend`
**Milestone :** `Sprint`
**Assignee :** Lou PELLEGRINO
**Parent :** EPIC-2

**Description :**
```
Implement the PostgreSQL connection pool using SQLx, initialize it on server startup, and make it available to all route handlers via Axum's application state.

## Definition of Done
- [ ] SQLx connection pool is initialized on server startup
- [ ] Pool is injected into Axum's application state (`axum::Extension` or `State`)
- [ ] Server fails to start with a clear error if `DATABASE_URL` is missing or unreachable
- [ ] A simple query (e.g., `SELECT 1`) runs successfully in tests
- [ ] Connection pool size is configurable via `.env`
```

**Commande gh :**
```bash
gh issue create \
  --title "SERVER: set up PostgreSQL connection pool with SQLx" \
  --label "backend" \
  --milestone "Sprint" \
  --body "Implement the PostgreSQL connection pool using SQLx, initialized on server startup and injected into Axum state.

## Definition of Done
- [ ] SQLx pool initialized on startup
- [ ] Pool injected into Axum application state
- [ ] Server fails clearly if \`DATABASE_URL\` is missing
- [ ] Simple query runs successfully in tests
- [ ] Pool size configurable via \`.env\`"
```

---

#### SERVER-3

**Titre :** `SERVER: implement presigned upload URL route`

**Labels :** `backend`
**Milestone :** `Sprint`
**Assignee :** Lou PELLEGRINO
**Parent :** EPIC-2

**Description :**
```
Implement the route that generates a presigned MinIO PUT URL and returns it to the mobile client, allowing direct upload of the video to object storage.

## Endpoint
`POST /api/v1/analysis/video/request-upload`

## Request Body
```json
{
  "filename": "climb_video.mp4",
  "content_type": "video/mp4"
}
```

## Response (200)
```json
{
  "upload_url": "http://localhost:9000/ascension-videos/...?X-Amz-Signature=...",
  "video_id": "uuid"
}
```

## Definition of Done
- [ ] Route returns a valid presigned PUT URL pointing to MinIO
- [ ] A new `videos` record is created in PostgreSQL with `status = "pending"`
- [ ] `video_id` (UUID) is included in the response for tracking
- [ ] URL expires after a configurable duration (e.g., 15 minutes)
- [ ] A video file can be uploaded to MinIO using the returned URL (manual test)
- [ ] Route returns appropriate errors for missing/invalid request body
```

**Commande gh :**
```bash
gh issue create \
  --title "SERVER: implement presigned upload URL route" \
  --label "backend" \
  --milestone "Sprint" \
  --body "Implement POST /api/v1/analysis/video/request-upload — returns a presigned MinIO PUT URL for direct video upload.

## Definition of Done
- [ ] Route returns a valid presigned PUT URL for MinIO
- [ ] New \`videos\` record created with \`status = \"pending\"\`
- [ ] \`video_id\` UUID included in response
- [ ] URL expires after configurable duration
- [ ] Manual test: file uploadable via returned URL
- [ ] Proper errors on invalid request body"
```

---

#### SERVER-4

**Titre :** `SERVER: implement analysis trigger route`

**Labels :** `backend`
**Milestone :** `Sprint`
**Assignee :** Lou PELLEGRINO
**Parent :** EPIC-2

**Description :**
```
Implement the route that triggers a video analysis by publishing a job message to the RabbitMQ `analysis_jobs` queue.

## Endpoint
`POST /api/v1/analysis/video/start`

## Request Body
```json
{
  "video_id": "uuid"
}
```

## Response (202)
```json
{
  "analysis_id": "uuid",
  "status": "queued"
}
```

## Message Published to RabbitMQ
```json
{
  "analysis_id": "uuid",
  "video_id": "uuid",
  "storage_url": "s3://ascension-videos/...",
  "created_at": "2026-03-02T12:00:00Z"
}
```

## Definition of Done
- [ ] Route validates that `video_id` exists and is in `uploaded` status
- [ ] A new `analyses` record is created with `status = "queued"`
- [ ] Message is published to `analysis_jobs` queue with correct schema
- [ ] Route returns `202 Accepted` with `analysis_id` and `status`
- [ ] Route returns `404` if `video_id` does not exist
- [ ] Route returns `409` if an analysis is already in progress for this video
```

**Commande gh :**
```bash
gh issue create \
  --title "SERVER: implement analysis trigger route" \
  --label "backend" \
  --milestone "Sprint" \
  --body "Implement POST /api/v1/analysis/video/start — publishes a job to RabbitMQ analysis_jobs queue.

## Definition of Done
- [ ] Route validates \`video_id\` exists and is in \`uploaded\` status
- [ ] New \`analyses\` record created with \`status = \"queued\"\`
- [ ] Message published to \`analysis_jobs\` queue with correct schema
- [ ] Returns \`202 Accepted\` with \`analysis_id\` and \`status\`
- [ ] Returns \`404\` if \`video_id\` not found
- [ ] Returns \`409\` if analysis already in progress"
```

---

#### SERVER-5

**Titre :** `SERVER: implement analysis result fetch route`

**Labels :** `backend`
**Milestone :** `Sprint`
**Assignee :** Lou PELLEGRINO
**Parent :** EPIC-2

**Description :**
```
Implement the route that returns the analysis result stored in PostgreSQL, enabling the mobile app to retrieve keypoints and feedback.

## Endpoint
`GET /api/v1/analysis/video/:id`

## Response (200)
```json
{
  "analysis_id": "uuid",
  "status": "completed",
  "result": {
    "keypoints": [...],
    "angles": {
      "left_elbow": 145.2,
      "right_knee": 92.1
    },
    "feedback": ["Keep your hips closer to the wall"]
  },
  "completed_at": "2026-03-02T12:05:00Z"
}
```

## Definition of Done
- [ ] Route returns `200` with the full result JSON when `status = "completed"`
- [ ] Route returns `202` with `{ "status": "processing" }` when analysis is still running
- [ ] Route returns `404` if `analysis_id` does not exist
- [ ] `result_json` JSONB field is correctly deserialized and returned
- [ ] Response is consistent with the schema defined in the API specification
```

**Commande gh :**
```bash
gh issue create \
  --title "SERVER: implement analysis result fetch route" \
  --label "backend" \
  --milestone "Sprint" \
  --body "Implement GET /api/v1/analysis/video/:id — returns the analysis result from PostgreSQL.

## Definition of Done
- [ ] Returns \`200\` with result JSON when completed
- [ ] Returns \`202\` with \`{ \"status\": \"processing\" }\` when still running
- [ ] Returns \`404\` if not found
- [ ] \`result_json\` JSONB correctly deserialized
- [ ] Response consistent with API specification"
```

---

#### SERVER-6

**Titre :** `SERVER: implement RabbitMQ result consumer to store AI results`

**Labels :** `backend`
**Milestone :** `Sprint`
**Assignee :** Gianni TUERO
**Parent :** EPIC-2 / EPIC-5

**Description :**
```
Implement the background consumer on the Rust side that listens to the `analysis_results` RabbitMQ queue, receives the JSON result from the AI worker, and stores it in the `analyses` PostgreSQL table.

## Definition of Done
- [ ] Consumer starts as a Tokio background task on server startup
- [ ] Consumer successfully receives messages from `analysis_results`
- [ ] Result JSON is parsed and stored in the `analyses.result_json` JSONB column
- [ ] `analyses.status` is updated to `"completed"` after successful storage
- [ ] `analyses.completed_at` timestamp is set on completion
- [ ] Message is ACKed only after successful DB write
- [ ] Consumer logs errors clearly without crashing on malformed messages
```

**Commande gh :**
```bash
gh issue create \
  --title "SERVER: implement RabbitMQ result consumer to store AI results" \
  --label "backend" \
  --milestone "Sprint" \
  --body "Implement a background Tokio task that consumes from \`analysis_results\` and stores AI results in PostgreSQL.

## Definition of Done
- [ ] Consumer starts as Tokio background task on server startup
- [ ] Receives messages from \`analysis_results\` queue
- [ ] Result JSON stored in \`analyses.result_json\`
- [ ] Status updated to \`completed\` after successful storage
- [ ] \`completed_at\` timestamp set
- [ ] Message ACKed only after successful DB write
- [ ] Errors logged without crashing on malformed messages"
```

---

### 🟡 AI — Issues Enfants

---

#### AI-1

**Titre :** `AI: set up MediaPipe Pose and OpenCV video frame extraction`

**Labels :** `ai`
**Milestone :** `Sprint`
**Assignee :** Olivier POUECH
**Parent :** EPIC-3

**Description :**
```
Set up the MediaPipe Pose model and OpenCV pipeline to read a climbing video file and extract frames for pose estimation.

## Dependencies to add to requirements.txt
- `mediapipe`
- `opencv-python`

## Definition of Done
- [ ] `mediapipe` and `opencv-python` added to `requirements.txt`
- [ ] Video file is read frame by frame using `cv2.VideoCapture`
- [ ] MediaPipe Pose model is initialized with `min_detection_confidence=0.5`
- [ ] Pose estimation runs successfully on at least one test frame
- [ ] Function `extract_keypoints(video_path: str) -> list[dict]` is implemented
- [ ] Unit test passes with a sample video file
```

**Commande gh :**
```bash
gh issue create \
  --title "AI: set up MediaPipe Pose and OpenCV video frame extraction" \
  --label "ai" \
  --milestone "Sprint" \
  --body "Set up MediaPipe Pose and OpenCV to read a climbing video and extract frames for pose estimation.

## Definition of Done
- [ ] \`mediapipe\` and \`opencv-python\` added to \`requirements.txt\`
- [ ] Video read frame by frame with \`cv2.VideoCapture\`
- [ ] MediaPipe Pose model initialized
- [ ] Pose estimation runs on at least one test frame
- [ ] Function \`extract_keypoints(video_path)\` implemented
- [ ] Unit test passes with a sample video"
```

---

#### AI-2

**Titre :** `AI: implement keypoint extraction and joint angle computation`

**Labels :** `ai`
**Milestone :** `Sprint`
**Assignee :** Olivier POUECH
**Parent :** EPIC-3

**Description :**
```
Implement the logic to extract MediaPipe's 33 pose landmarks per frame and compute key joint angles relevant to climbing movement analysis.

## Joint Angles to Compute (minimum)
- Left/Right elbow angle (shoulder–elbow–wrist)
- Left/Right knee angle (hip–knee–ankle)
- Left/Right hip angle (shoulder–hip–knee)

## Definition of Done
- [ ] All 33 MediaPipe landmarks are extracted per frame
- [ ] Landmark coordinates (x, y, z, visibility) are stored per frame
- [ ] `compute_angle(a, b, c)` utility function is implemented and tested
- [ ] Elbow, knee, and hip angles are computed for both sides
- [ ] Angles are averaged across relevant frames (configurable)
- [ ] Output structure: `{ "angles": { "left_elbow": float, ... } }`
```

**Commande gh :**
```bash
gh issue create \
  --title "AI: implement keypoint extraction and joint angle computation" \
  --label "ai" \
  --milestone "Sprint" \
  --body "Implement extraction of MediaPipe's 33 landmarks and compute key joint angles for climbing analysis.

## Definition of Done
- [ ] All 33 landmarks extracted per frame
- [ ] \`compute_angle(a, b, c)\` utility tested
- [ ] Elbow, knee, and hip angles computed for both sides
- [ ] Output: \`{ \"angles\": { \"left_elbow\": float, ... } }\`"
```

---

#### AI-3

**Titre :** `AI: define and serialize JSON result structure`

**Labels :** `ai`
**Milestone :** `Sprint`
**Assignee :** Olivier POUECH
**Parent :** EPIC-3

**Description :**
```
Define the final JSON result structure produced by the AI worker and implement the serialization logic to ensure the backend and mobile can consume it reliably.

## Result Schema
```json
{
  "analysis_id": "uuid",
  "keypoints": [
    {
      "frame": 0,
      "landmarks": [
        { "id": 0, "name": "nose", "x": 0.52, "y": 0.21, "z": -0.01, "visibility": 0.99 }
      ]
    }
  ],
  "angles": {
    "left_elbow": 145.2,
    "right_elbow": 138.7,
    "left_knee": 92.1,
    "right_knee": 88.4,
    "left_hip": 110.5,
    "right_hip": 107.3
  },
  "feedback": [
    "Keep your hips closer to the wall",
    "Straighten your left arm on the next move"
  ]
}
```

## Definition of Done
- [ ] Result schema matches the above specification
- [ ] Result is serializable to JSON using `json.dumps()` without errors
- [ ] Schema is documented in the codebase (docstring or README)
- [ ] Feedback list contains at least one item based on angle thresholds
- [ ] Unit test validates JSON serialization of a sample result
```

**Commande gh :**
```bash
gh issue create \
  --title "AI: define and serialize JSON result structure" \
  --label "ai" \
  --milestone "Sprint" \
  --body "Define and implement the final JSON result structure produced by the AI worker.

## Definition of Done
- [ ] Result schema includes \`keypoints\`, \`angles\`, and \`feedback\`
- [ ] Serializable with \`json.dumps()\` without errors
- [ ] Schema documented in codebase
- [ ] At least one feedback item based on angle thresholds
- [ ] Unit test validates serialization"
```

---

#### AI-4

**Titre :** `AI: implement RabbitMQ consumer for analysis jobs`

**Labels :** `ai`
**Milestone :** `Sprint`
**Assignee :** Gianni TUERO
**Parent :** EPIC-3 / EPIC-5

**Description :**
```
Implement the RabbitMQ consumer in the Python AI worker that listens to the `analysis_jobs` queue and processes incoming analysis requests.

## Dependencies to add to requirements.txt
- `pika`

## Message Schema Expected
```json
{
  "analysis_id": "uuid",
  "video_id": "uuid",
  "storage_url": "s3://ascension-videos/...",
  "created_at": "2026-03-02T12:00:00Z"
}
```

## Definition of Done
- [ ] `pika` added to `requirements.txt`
- [ ] Consumer connects to RabbitMQ using credentials from `.env`
- [ ] Consumer listens to `analysis_jobs` queue in a blocking loop
- [ ] Incoming message is parsed and validated (missing fields → NACK)
- [ ] Video file is fetched from MinIO using `storage_url`
- [ ] Message is ACKed after successful processing
- [ ] Consumer reconnects automatically on connection drop
```

**Commande gh :**
```bash
gh issue create \
  --title "AI: implement RabbitMQ consumer for analysis jobs" \
  --label "ai" \
  --milestone "Sprint" \
  --body "Implement the RabbitMQ consumer (pika) in the Python worker for the \`analysis_jobs\` queue.

## Definition of Done
- [ ] \`pika\` added to \`requirements.txt\`
- [ ] Consumer connects to RabbitMQ from \`.env\`
- [ ] Consumer listens to \`analysis_jobs\` in a blocking loop
- [ ] Message parsed and validated (invalid → NACK)
- [ ] Video fetched from MinIO using \`storage_url\`
- [ ] Message ACKed after successful processing
- [ ] Auto-reconnect on connection drop"
```

---

#### AI-5

**Titre :** `AI: implement RabbitMQ result publisher`

**Labels :** `ai`
**Milestone :** `Sprint`
**Assignee :** Olivier POUECH
**Parent :** EPIC-3 / EPIC-5

**Description :**
```
Implement the RabbitMQ publisher in the Python AI worker that sends the JSON analysis result back to the `analysis_results` queue after processing is complete.

## Definition of Done
- [ ] Publisher connects to RabbitMQ using credentials from `.env`
- [ ] Result JSON is published to `analysis_results` with `delivery_mode=2` (persistent)
- [ ] `analysis_id` is included in the message for correlation
- [ ] Publisher handles connection errors gracefully (retry once before failing)
- [ ] Integration test: publish → backend consumer → PostgreSQL row updated
```

**Commande gh :**
```bash
gh issue create \
  --title "AI: implement RabbitMQ result publisher" \
  --label "ai" \
  --milestone "Sprint" \
  --body "Implement the RabbitMQ publisher in the Python AI worker to send results to \`analysis_results\`.

## Definition of Done
- [ ] Publisher connects from \`.env\` credentials
- [ ] Result published to \`analysis_results\` with persistent delivery
- [ ] \`analysis_id\` included for correlation
- [ ] Connection errors handled (retry once)
- [ ] Integration test: publish → DB row updated"
```

---

### 🟣 MOBILE — Issues Enfants

---

#### MOBILE-1

**Titre :** `MOBILE: add required dependencies to pubspec.yaml`

**Labels :** `mobile`
**Milestone :** `Sprint`
**Assignee :** Christophe VANDEVOIR
**Parent :** EPIC-4

**Description :**
```
Add all required Flutter dependencies to `pubspec.yaml` for the prototype: HTTP client, video picker, and any other necessary packages.

## Dependencies to Add
- `http` or `dio` — HTTP client for API communication
- `image_picker` — video selection from gallery or camera
- `video_player` — local video playback (for result overlay)
- `provider` or `riverpod` — state management (if not already present)

## Definition of Done
- [ ] All packages added to `pubspec.yaml`
- [ ] `flutter pub get` runs without errors
- [ ] No dependency conflicts in the dependency graph
- [ ] `moon run mobile:dev` builds successfully after dependency addition
```

**Commande gh :**
```bash
gh issue create \
  --title "MOBILE: add required dependencies to pubspec.yaml" \
  --label "mobile" \
  --milestone "Sprint" \
  --body "Add all required Flutter dependencies for the prototype: HTTP client, video picker, video player.

## Definition of Done
- [ ] \`http\`/\`dio\`, \`image_picker\`, \`video_player\` added to \`pubspec.yaml\`
- [ ] \`flutter pub get\` runs without errors
- [ ] No dependency conflicts
- [ ] \`moon run mobile:dev\` builds successfully"
```

---

#### MOBILE-2

**Titre :** `MOBILE: implement video picker and local video handling`

**Labels :** `mobile`
**Milestone :** `Sprint`
**Assignee :** Christophe VANDEVOIR
**Parent :** EPIC-4

**Description :**
```
Implement the video selection UI using `image_picker`, allowing the user to pick a video from their device gallery. Handle the local video file reference for subsequent upload.

## Definition of Done
- [ ] "Select Video" button opens the device gallery/files
- [ ] Selected video path is stored in application state
- [ ] Video name and file size are displayed in the UI after selection
- [ ] Permissions are handled correctly on both Android and iOS
- [ ] Error is shown if no video is selected and the user tries to proceed
- [ ] Video selection works on both Android and iOS physical devices
```

**Commande gh :**
```bash
gh issue create \
  --title "MOBILE: implement video picker and local video handling" \
  --label "mobile" \
  --milestone "Sprint" \
  --body "Implement video selection from device gallery using \`image_picker\`.

## Definition of Done
- [ ] 'Select Video' opens device gallery
- [ ] Selected video path stored in state
- [ ] Video name and file size displayed after selection
- [ ] Permissions handled on Android and iOS
- [ ] Error shown if no video selected before proceeding
- [ ] Works on physical devices"
```

---

#### MOBILE-3

**Titre :** `MOBILE: implement HTTP client service for backend communication`

**Labels :** `mobile`
**Milestone :** `Sprint`
**Assignee :** Christophe VANDEVOIR
**Parent :** EPIC-4

**Description :**
```
Implement a reusable HTTP client service in Flutter that abstracts all communication with the Rust backend (presigned URL request, analysis trigger, result fetch).

## Methods Required
- `Future<UploadUrlResponse> requestUploadUrl(String filename, String contentType)`
- `Future<AnalysisResponse> startAnalysis(String videoId)`
- `Future<AnalysisResult> getAnalysisResult(String analysisId)`

## Definition of Done
- [ ] HTTP client service is implemented as a Dart class (or provider)
- [ ] Base URL is configurable via environment/config
- [ ] All 3 methods are implemented and return typed response objects
- [ ] HTTP errors (4xx, 5xx) are handled and surfaced to the UI
- [ ] Service is unit-tested with a mock HTTP client
```

**Commande gh :**
```bash
gh issue create \
  --title "MOBILE: implement HTTP client service for backend communication" \
  --label "mobile" \
  --milestone "Sprint" \
  --body "Implement a reusable HTTP client service abstracting all backend communication (presigned URL, analysis trigger, result fetch).

## Definition of Done
- [ ] HTTP service class implemented
- [ ] Base URL configurable
- [ ] \`requestUploadUrl\`, \`startAnalysis\`, \`getAnalysisResult\` implemented
- [ ] HTTP errors handled and surfaced to UI
- [ ] Unit-tested with mock HTTP client"
```

---

#### MOBILE-4

**Titre :** `MOBILE: implement video upload flow via presigned URL`

**Labels :** `mobile`
**Milestone :** `Sprint`
**Assignee :** Christophe VANDEVOIR
**Parent :** EPIC-4

**Description :**
```
Implement the video upload flow: request a presigned URL from the backend, then upload the local video file directly to MinIO using an HTTP PUT request.

## Upload Flow
1. Call `POST /api/v1/analysis/video/request-upload` → receive `upload_url` and `video_id`
2. Execute `PUT {upload_url}` with the video file as the request body
3. Store `video_id` in state for subsequent analysis trigger

## Definition of Done
- [ ] App requests a presigned URL from the backend before upload
- [ ] Video is uploaded directly to MinIO via HTTP PUT (not through the backend)
- [ ] Upload progress is shown to the user (progress bar or percentage)
- [ ] `video_id` is stored in state after successful upload
- [ ] Upload errors are displayed clearly to the user
- [ ] Upload works with a video file > 10 MB
```

**Commande gh :**
```bash
gh issue create \
  --title "MOBILE: implement video upload flow via presigned URL" \
  --label "mobile" \
  --milestone "Sprint" \
  --body "Implement video upload: request presigned URL from backend, then PUT video directly to MinIO.

## Definition of Done
- [ ] Presigned URL requested from backend before upload
- [ ] Video uploaded to MinIO via HTTP PUT (bypass backend)
- [ ] Upload progress displayed
- [ ] \`video_id\` stored in state after upload
- [ ] Upload errors displayed clearly
- [ ] Works with video > 10 MB"
```

---

#### MOBILE-5

**Titre :** `MOBILE: implement analysis trigger and result polling`

**Labels :** `mobile`
**Milestone :** `Sprint`
**Assignee :** Christophe VANDEVOIR
**Parent :** EPIC-4

**Description :**
```
Implement the "Analyse" button flow: trigger the analysis on the backend, then poll for the result until it is completed.

## Flow
1. User taps "Analyse" → `POST /api/v1/analysis/video/start` → receive `analysis_id`
2. Poll `GET /api/v1/analysis/video/:id` every 2 seconds until `status = "completed"`
3. Navigate to result screen with the response data

## Definition of Done
- [ ] "Analyse" button calls `startAnalysis(videoId)` and stores `analysis_id`
- [ ] App polls the result endpoint every 2 seconds
- [ ] Loading indicator is shown during polling
- [ ] Polling stops when `status = "completed"` or on error
- [ ] Maximum polling duration is capped (e.g., 2 minutes timeout)
- [ ] User is informed if the analysis fails or times out
```

**Commande gh :**
```bash
gh issue create \
  --title "MOBILE: implement analysis trigger and result polling" \
  --label "mobile" \
  --milestone "Sprint" \
  --body "Implement the 'Analyse' button: trigger analysis, then poll the backend until result is ready.

## Definition of Done
- [ ] 'Analyse' button calls analysis trigger and stores \`analysis_id\`
- [ ] App polls result every 2 seconds
- [ ] Loading indicator shown during polling
- [ ] Polling stops on \`status = completed\` or error
- [ ] Timeout capped at 2 minutes
- [ ] User informed on failure or timeout"
```

---

#### MOBILE-6

**Titre :** `MOBILE: implement analysis result display screen`

**Labels :** `mobile`
**Milestone :** `Sprint`
**Assignee :** Christophe VANDEVOIR
**Parent :** EPIC-4

**Description :**
```
Implement the result display screen that shows the analysis output returned by the backend. At minimum, display the raw JSON data; ideally, render a basic skeleton overlay using `CustomPainter`.

## Definition of Done
- [ ] Result screen receives and displays the analysis result
- [ ] Joint angles are displayed in a readable format (e.g., cards or list)
- [ ] Feedback strings are displayed as a list
- [ ] **Bonus:** Basic skeleton overlay rendered on a static frame using `CustomPainter`
- [ ] "Analyse Again" or "Back" navigation is available
- [ ] Screen handles empty or null result gracefully
```

**Commande gh :**
```bash
gh issue create \
  --title "MOBILE: implement analysis result display screen" \
  --label "mobile" \
  --milestone "Sprint" \
  --body "Implement the result screen showing analysis output (angles, feedback, optional skeleton overlay).

## Definition of Done
- [ ] Result screen displays the analysis result
- [ ] Joint angles displayed in readable format
- [ ] Feedback strings displayed as list
- [ ] Bonus: basic skeleton overlay with \`CustomPainter\`
- [ ] Navigation back available
- [ ] Handles null/empty result gracefully"
```

---

### 🔴 E2E / BONUS — Issues Enfants

---

#### E2E-1

**Titre :** `E2E: run integration smoke test for the full data flow`

**Labels :** `backend`, `ai`, `mobile`, `infra`
**Milestone :** `Demo Checkpoint`
**Assignee :** Nicolas TORO
**Parent :** EPIC-6

**Description :**
```
Manually run the full end-to-end data flow using a real climbing video and verify each step produces the expected output.

## Test Script
1. Start all services: `docker compose up -d`
2. Start backend: `moon run server:dev`
3. Start AI worker: `moon run ai:dev`
4. Start mobile app: `moon run mobile:dev`
5. Select a test climbing video on the mobile app
6. Trigger the upload flow and confirm video appears in MinIO
7. Trigger analysis and confirm job appears in RabbitMQ
8. Confirm AI worker processes the job and publishes a result
9. Confirm backend stores the result in PostgreSQL
10. Confirm mobile app displays the result

## Definition of Done
- [ ] All 10 steps complete successfully without manual intervention
- [ ] Each step is verified with a log entry or UI confirmation
- [ ] Test video is stored in the repository under `tests/fixtures/`
- [ ] Any blocking issues are documented as new child issues
```

**Commande gh :**
```bash
gh issue create \
  --title "E2E: run integration smoke test for the full data flow" \
  --label "backend,ai,mobile,infra" \
  --milestone "Demo Checkpoint" \
  --assignee "@me" \
  --body "Manually run the full end-to-end flow with a real climbing video and verify each step.

## Definition of Done
- [ ] All 10 steps of the test script complete successfully
- [ ] Each step verified with log/UI confirmation
- [ ] Test video stored under \`tests/fixtures/\`
- [ ] Blocking issues documented as new child issues"
```

---

#### E2E-2

**Titre :** `E2E: prepare demo video and presentation environment`

**Labels :** `infra`, `docs`
**Milestone :** `Finalization`
**Assignee :** Nicolas TORO
**Parent :** EPIC-6

**Description :**
```
Prepare the demo environment for the final presentation: select a compelling test climbing video, verify the full flow works reliably, and document the demo script for the 15-minute pitch.

## Definition of Done
- [ ] A short climbing video (30–60s) is selected and stored in the repository
- [ ] Full end-to-end flow runs successfully 3 consecutive times with the demo video
- [ ] Demo script (step-by-step) is written and shared with the team
- [ ] All services start in under 2 minutes from cold
- [ ] Fallback plan documented in case of live demo failure
```

**Commande gh :**
```bash
gh issue create \
  --title "E2E: prepare demo video and presentation environment" \
  --label "infra,docs" \
  --milestone "Finalization" \
  --assignee "@me" \
  --body "Prepare the demo environment and script for the 15-minute prototype pitch.

## Definition of Done
- [ ] Short climbing video (30–60s) selected and stored
- [ ] Full flow runs successfully 3 consecutive times
- [ ] Demo script written and shared with team
- [ ] All services start in under 2 minutes from cold
- [ ] Fallback plan documented"
```

---

#### BONUS-1

**Titre :** `AUTH: implement basic JWT authentication (register & login)`

**Labels :** `backend`, `mobile`
**Milestone :** `Finalization`
**Assignee :** Lou PELLEGRINO / Nicolas TORO
**Parent :** *(standalone bonus)*

**Description :**
```
If time allows, implement basic JWT authentication: register and login routes on the backend, and token storage + injection in the mobile app.

## Endpoints
- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`

## Definition of Done
- [ ] `POST /auth/register` creates a user in PostgreSQL with hashed password (`bcrypt` or `argon2`)
- [ ] `POST /auth/login` returns a signed JWT access token
- [ ] JWT is validated on protected routes via Axum middleware
- [ ] Mobile app stores the token securely (e.g., `flutter_secure_storage`)
- [ ] Mobile app includes `Authorization: Bearer <token>` header on all API requests
- [ ] Invalid/expired tokens return `401 Unauthorized`
```

**Commande gh :**
```bash
gh issue create \
  --title "AUTH: implement basic JWT authentication (register & login)" \
  --label "backend,mobile" \
  --milestone "Finalization" \
  --body "Implement basic JWT authentication if time allows: register, login, and token validation middleware.

## Definition of Done
- [ ] \`POST /auth/register\` creates user with hashed password
- [ ] \`POST /auth/login\` returns signed JWT
- [ ] JWT validated on protected routes via Axum middleware
- [ ] Mobile stores token with \`flutter_secure_storage\`
- [ ] API requests include \`Authorization: Bearer\` header
- [ ] Invalid tokens return \`401 Unauthorized\`"
```

---

## Récapitulatif des Issues

| # | Titre | Scope | Type | Milestone | Assignee |
|---|-------|-------|------|-----------|----------|
| 1 | INFRA: set up local development infrastructure | EPIC-1 | Epic | Definition | Nicolas TORO |
| 2 | INFRA: create base Docker Compose configuration | INFRA-1 | Child | Definition | Nicolas TORO |
| 3 | INFRA: set up PostgreSQL with initial schema | INFRA-2 | Child | Definition | Lou PELLEGRINO |
| 4 | INFRA: configure RabbitMQ with required queues | INFRA-3 | Child | Definition | Gianni TUERO |
| 5 | INFRA: configure MinIO with initial bucket | INFRA-4 | Child | Definition | Nicolas TORO |
| 6 | SERVER: initialize Rust/Axum backend | EPIC-2 | Epic | Sprint | Lou PELLEGRINO |
| 7 | SERVER: initialize project structure & dependencies | SERVER-1 | Child | Sprint | Lou PELLEGRINO |
| 8 | SERVER: set up PostgreSQL connection pool | SERVER-2 | Child | Sprint | Lou PELLEGRINO |
| 9 | SERVER: implement presigned upload URL route | SERVER-3 | Child | Sprint | Lou PELLEGRINO |
| 10 | SERVER: implement analysis trigger route | SERVER-4 | Child | Sprint | Lou PELLEGRINO |
| 11 | SERVER: implement analysis result fetch route | SERVER-5 | Child | Sprint | Lou PELLEGRINO |
| 12 | SERVER: implement RabbitMQ result consumer | SERVER-6 | Child | Sprint | Gianni TUERO |
| 13 | AI: implement MediaPipe pose estimation pipeline | EPIC-3 | Epic | Sprint | Olivier POUECH |
| 14 | AI: set up MediaPipe Pose & OpenCV | AI-1 | Child | Sprint | Olivier POUECH |
| 15 | AI: implement keypoint extraction & angle computation | AI-2 | Child | Sprint | Olivier POUECH |
| 16 | AI: define and serialize JSON result structure | AI-3 | Child | Sprint | Olivier POUECH |
| 17 | AI: implement RabbitMQ consumer | AI-4 | Child | Sprint | Gianni TUERO |
| 18 | AI: implement RabbitMQ result publisher | AI-5 | Child | Sprint | Olivier POUECH |
| 19 | MOBILE: build Flutter UI | EPIC-4 | Epic | Sprint | Christophe VANDEVOIR |
| 20 | MOBILE: add required dependencies | MOBILE-1 | Child | Sprint | Christophe VANDEVOIR |
| 21 | MOBILE: implement video picker | MOBILE-2 | Child | Sprint | Christophe VANDEVOIR |
| 22 | MOBILE: implement HTTP client service | MOBILE-3 | Child | Sprint | Christophe VANDEVOIR |
| 23 | MOBILE: implement video upload via presigned URL | MOBILE-4 | Child | Sprint | Christophe VANDEVOIR |
| 24 | MOBILE: implement analysis trigger & polling | MOBILE-5 | Child | Sprint | Christophe VANDEVOIR |
| 25 | MOBILE: implement result display screen | MOBILE-6 | Child | Sprint | Christophe VANDEVOIR |
| 26 | BROKER: implement RabbitMQ message flow | EPIC-5 | Epic | Sprint | Gianni TUERO |
| 27 | E2E: validate full end-to-end user journey | EPIC-6 | Epic | Demo Checkpoint | Nicolas TORO |
| 28 | E2E: run integration smoke test | E2E-1 | Child | Demo Checkpoint | Nicolas TORO |
| 29 | E2E: prepare demo video & presentation | E2E-2 | Child | Finalization | Nicolas TORO |
| 30 | AUTH: implement basic JWT authentication | BONUS-1 | Bonus | Finalization | Lou / Nicolas |

---

> **Total :** 6 epics + 22 issues enfants + 1 bonus = **29 issues**
