---
id: ab77caf4-081b-4c22-8817-d8570baadf55
---

:::success
**Version:** 2.3
:::

---

# Development Environment Setup

---

## Overview

The development environment runs all services on a single machine using Docker Compose. This setup is optimized for rapid iteration and local testing.

---

## Architecture Diagram

```mermaid
graph TB
    subgraph "Developer Machine"
        subgraph "Docker Compose Network"
            API[Go API :8080]
            DB[(PostgreSQL :5432)]
            RabbitMQ[(RabbitMQ :5672/:15672)]
            RustFS[RustFS :9000/:9001]
            Worker[Python AI Worker]
        end

        Flutter[Flutter App<br/>iOS Simulator/Android Emulator]
    end

    Flutter -->|HTTP/WS| API
    Flutter -->|Direct Upload| RustFS
    API --> DB
    API --> RabbitMQ
    Worker --> RabbitMQ
    Worker --> RustFS
    Worker --> DB

    style API fill:#e1f5ff
    style Worker fill:#fff4e1
    style DB fill:#f0f0f0
    style RabbitMQ fill:#ffe1e1
    style RustFS fill:#e1ffe1

```

---

## Prerequisites

### Required Software

1. **Docker Desktop** (v20.10+)

   ```bash
   # Install on macOS
   brew install --cask docker

   # Install on Linux
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh

   ```

2. **Docker Compose** (v2.0+)
   - Included with Docker Desktop on macOS/Windows
   - Linux: `sudo apt-get install docker-compose-plugin`
3. **Go Toolchain** (1.27.1+)

   ```bash
   # Download and install Go from https://go.dev/dl/
   # E.g. Linux installation:
   wget https://go.dev/dl/go1.27.1.linux-amd64.tar.gz
   sudo tar -C /usr/local -xzf go1.27.1.linux-amd64.tar.gz
   export PATH=$PATH:/usr/local/go/bin

   ```

4. **Flutter SDK** (3.16+)

   ```bash
   # macOS
   brew install flutter

   # Or download from https://docs.flutter.dev/get-started/install

   ```

5. **uv** (Python package & environment manager)

# Install uv

curl -LsSf [https://astral.sh/uv/install.sh](https://astral.sh/uv/install.sh) | sh

# Verify installation

uv --version

````

### Optional Tools

- **pgAdmin** or **DBeaver**: Database GUI
- **RabbitMQ Management UI**: Built-in at http://localhost:15672
- **Postman** or **Insomnia**: API testing

---

## Project Structure

The project uses a **monorepo managed with [moonrepo](https://moonrepo.dev)**. All services are located under `apps/` in the main `Ascension` repository:

```text
Ascension/                  # Monorepo root
├── .moon/
│   ├── workspace.yml       # Projects: server, ai, mobile
│   └── toolchain.yml       # Pinned toolchain versions
├── docker-compose.yml      # Orchestration of all services
├── .env.example            # Environment variables template
├── README.md
└── apps/
    ├── server/             # Go API server
    │   ├── moon.yml
    │   ├── go.mod
    │   ├── go.sum
    │   ├── Dockerfile
    │   ├── cmd/
    │   │   ├── server/main.go
    │   │   └── cron/main.go
    │   ├── migrations/
    │   └── internal/
    ├── ai/                 # Python AI worker
    │   ├── moon.yml
    │   ├── pyproject.toml
    │   ├── Dockerfile
    │   ├── scripts/        # download-model.sh
    │   ├── tests/
    │   └── src/
    │       ├── worker/     # CLI, pipeline steps, handlers
    │       ├── services/   # rabbitmq, postgresql, rustfs, llm
    │       ├── common/
    │       ├── shared/     # generated from schemas/
    │       └── producer.py
    └── mobile/             # Flutter mobile app
        ├── moon.yml
        ├── pubspec.yaml
        └── lib/
            └── main.dart

````

**Why moonrepo instead of submodules?**

- Single `git clone` — everything is already in the repo
- Unified task runner with caching (`moon run server:dev`)
- Toolchain versions (Go, Python) pinned in `.moon/toolchain.yml`
- Affected-only CI builds

---

## Step-by-Step Setup

### 1\. Install moon

```bash
# macOS / Linux
curl -fsSL https://moonrepo.dev/install/moon.sh | bash

# Make sure ~/.moon/bin is in your PATH
export PATH="$HOME/.moon/bin:$PATH"

# Verify
moon --version

```

### 2\. Clone Repository

```bash
# Simple clone — no --recursive needed
git clone https://github.com/Ascension-EIP/Ascension.git
cd Ascension

```

**Verify the structure:**

````bash
ls apps/
# You should see: server/  ai/  mobile/

# List moon projects
moon project --list
### 3. Environment Configuration

Create `.env` file from template:

```bash
cp .env.example .env

````

Environment Variable Strategy

We follow a dual-strategy for environment variables to balance local developer experience with production security and reliability.

| Feature       | Local Development (Native) | Production / Docker (`--profile prod`)            |
| ------------- | -------------------------- | ------------------------------------------------- |
| **Source**    | Root `.env` file           | Hardcoded in `docker-compose.yml`                 |
| **Hostnames** | `localhost`                | Internal service names (`rabbitmq`, `postgresql`) |
| **Ports**     | Forwarded to host machine  | Internal container ports                          |

**Why this dual-approach?**

- **Native Context:** Allows you to run `moon run ai:dev` or `go run ./cmd/server` directly on your host machine while connecting to Dockerized infra services.
- **Docker Context:** Ensures that when the AI worker runs _inside_ a container (production), it uses internal network hostnames and avoids `.env` host mismatches.

Edit `.env`:

```bash
# PostgreSQL
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_USER=ascension
POSTGRES_PASSWORD=ascension
POSTGRES_DB=ascension
POSTGRES_PARAMS="sslmode=disable"
POSTGRES_MIGRATION=true
POSTGRES_DB_URL=postgres://ascension:ascension@localhost:5432/ascension

# RabbitMQ
RABBITMQ_HOST=localhost
RABBITMQ_PORT=5672
RABBITMQ_USER=ascension
RABBITMQ_PASS=ascension
RABBITMQ_TLS=false

# RustFS (S3-compatible storage), read by the AI worker
RUSTFS_ENDPOINT=http://localhost:9000
RUSTFS_ACCESS_KEY=ascension
RUSTFS_SECRET_KEY=ascension
RUSTFS_BUCKET=videos

# Legacy MINIO_* names, still read by the Go server and by docker-compose.
# Their values must stay equal to the RUSTFS_* ones above.
MINIO_ENDPOINT=http://localhost:9000
MINIO_ID=ascension
MINIO_SECRET=ascension
MINIO_BUCKET=videos
MINIO_SSL=false
MINIO_ROOT_USER=ascension
MINIO_ROOT_PASSWORD=ascension
MINIO_HOST=minio
MINIO_PORT=9000

# Backend Server
PORT=8080
HTTPS=false
AUTH_JWT_SECRET=your_jwt_secret_key_here
AUTH_JWT_EXP=15m
AUTH_SESSION_SECRET=user_session
AUTH_SESSION_EXP=168h
AUTH_SESSION_REMEMBER_EXP=720h
LOG_LEVEL=info
LOG_PRETTY=false

# AI Worker: LLM used for the advice step (any OpenAI-compatible API).
# Optional: without LLM_BASE_URL or LLM_MODEL the worker still starts and
# analyses finish without advice.
PYTHONUNBUFFERED=1
LLM_BASE_URL=https://generativelanguage.googleapis.com/v1beta/openai/
LLM_API_KEY=your_llm_api_key_here
LLM_MODEL=gemini-3.1-flash-lite

# Read by the scripts in .github/scripts (commit and PR review tooling), not by the AI worker
GEMINI_API_KEY=your_gemini_api_key_here
GEMINI_MODEL=gemini-3.1-flash-lite

```

### 4\. Launch Infrastructure

Start all core infrastructure services:

```bash
docker-compose up -d

```

This launches:

- `postgresql` (port 5432)
- `rabbitmq` (port 5672 for AMQP, 15672 for management UI)
- `rustfs` (port 9000 for the S3 API, 9001 for the console)

Verify services are running:

```bash
docker-compose ps

```

Expected output:

```text
NAME                 SERVICE      STATUS
ascension-postgres   postgresql   running (healthy)
ascension-rabbitmq   rabbitmq     running (healthy)
ascension-rustfs     rustfs       running (healthy)

```

### 5\. Initialize Database

In Go, database migrations are automatically run on startup by the server using `golang-migrate` when `POSTGRES_MIGRATION=true`.

No external CLI installation is required for basic local runs. Simply booting the server container or running `moon run server:dev` will apply pending migrations automatically.

**Note**: Database migrations are located in `apps/server/migrations/`

The AI worker writes `status`, `progress`, `result`, `hints`, `error` and the timestamps of the `analyses` table, so **the migrations must be applied before the worker starts**, in particular `20261030200000_update_job_status_enum` (statuses `pending`, `started`, `running`, `success`, `failed`) and `20261030200100_add_analyses_hints` (`hints JSONB`). To apply them without starting the server, run `moon run server:migrate` (the `migrate` tool is installed by `moon run server:setup`).

**Note**: `docker-compose.yml` builds the `postgresql` service from `./apps/server/postgres`, which does not exist in the repository. `docker-compose up` only works where the image `ghcr.io/ascension-eip/ascension-postgres:latest` is already pulled. On a fresh machine, pull the image first or fix the compose file.

### 6\. Build and Run API Server

Option A: Using Docker (Production Profile)

```bash
# From Ascension root directory
docker-compose --profile prod up server -d

```

Option B: Using moon (Faster Iteration)

```bash
# From anywhere in the repo
moon run server:dev

```

Option C: Direct go run

```bash
cd apps/server
go run ./cmd/server

```

Verify API is healthy:

```bash
curl http://localhost:8080/healthz
# Expected: 204 No Content

```

### 7\. Set Up the AI Worker

The worker is documented in detail in the [AI worker README](../../../../../apps/ai/README.md). Short version:

Install Dependencies via moon

```bash
moon run ai:setup     # downloads the MediaPipe model if missing
moon run ai:install   # uv sync

```

Common AI moon Tasks

```bash
moon run ai:dev          # run the worker (loads .env)
moon run ai:test         # unit and functional tests, no infrastructure
moon run ai:coverage     # same tests with a coverage report
moon run ai:e2e          # real RabbitMQ, PostgreSQL and RustFS (see below)
moon run ai:pose-detect -- --video resources/example-2.mp4 --out /tmp/result.json
moon run ai:producer -- seed --video resources/example-2.mp4
moon run ai:lint
moon run ai:build

```

Or manually:

```bash
cd apps/ai
# Sync dependencies with uv (creates venv + installs all packages)
uv sync

```

Download the MediaPipe model

```bash
bash scripts/download-model.sh

```

This downloads the `pose_landmarker_full` model (~9 MB) to `apps/ai/resources/` unless it is already there.

Run Worker

```bash
# Via moon (recommended)
moon run ai:dev

# Or directly
cd apps/ai && uv run worker

```

Or using Docker (the service is in the `prod` profile):

```bash
docker-compose --profile prod up ai-worker -d

```

The worker needs PostgreSQL (migrated), RabbitMQ and RustFS, and the bucket `videos` must exist. The Go server creates the bucket at startup; `producer.py seed` creates it too. The `LLM_*` variables are optional.

Run a Pipeline Step Without Infrastructure

Every step is a sub-command and needs no RabbitMQ, database or storage:

```bash
cd apps/ai
uv run worker pose-detect --video resources/example-2.mp4 --out /tmp/result.json
uv run worker pose-advice --input /tmp/result.json --out /tmp/prompt.txt --dry-run

```

Trigger a Job By Hand

The Go server does not publish on the worker queues yet. `apps/ai/src/producer.py` stands in for it:

```bash
cd apps/ai
uv run python src/producer.py seed --video resources/example-2.mp4   # prints job_id and object_key
uv run python src/producer.py detect --job-id <job_id> --object-key <object_key>

```

Tests With Infrastructure

`moon run ai:e2e` starts the services through `root:db-up` and `server:migrate`. If port 5432 is used by another project, do not run it as is: start disposable containers on free ports and point the tests to them with `TEST_POSTGRES_URL`, `POSTGRES_PORT`, `RABBITMQ_PORT` and `RUSTFS_ENDPOINT` (see the README).

**Note**: The worker runs on CPU today; the [GPU Setup](#gpu-setup-optional) below is optional.

### 8\. Configure Flutter App

Update API Endpoint

Edit `apps/mobile/lib/config/api_config.dart`:

```dart
class ApiConfig {
  static const String baseUrl = 'http://localhost:8080';
  static const String wsUrl = 'ws://localhost:8080/ws';

  // For iOS Simulator, use:
  // static const String baseUrl = 'http://127.0.0.1:8080';

  // For Android Emulator, use:
  // static const String baseUrl = 'http://10.0.2.2:8080';
}

```

Install Dependencies

```bash
# Via moon
moon run mobile:install

# Or directly
cd apps/mobile
flutter pub get

```

Run App

```bash
# iOS Simulator
flutter run -d "iPhone 15 Pro"

# Android Emulator (start emulator first)
flutter emulator --launch <emulator_name>
flutter run -d <device_id>

```

---

## Docker Compose Configuration

### Complete `docker-compose.yml`

**Location**: `/Ascension/docker-compose.yml` (root of main repository)

This file orchestrates all services from the `apps/` directory:

```yaml
services:
  rustfs:
    image: rustfs/rustfs:1.0.4
    container_name: ascension-rustfs
    restart: unless-stopped
    ports:
      - "${MINIO_PORT:-9000}:9000"
      - "9001:9001"
    environment:
      RUSTFS_ACCESS_KEY: ${MINIO_ID:-ascension}
      RUSTFS_SECRET_KEY: ${MINIO_SECRET:-ascension}
    volumes:
      - rustfs_data:/data
    networks:
      - ascension-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/health"]
      interval: 10s
      timeout: 5s
      retries: 5

  rabbitmq:
    image: rabbitmq:4.3.5-management
    container_name: ascension-rabbitmq
    restart: unless-stopped
    ports:
      - "${RABBITMQ_PORT:-5672}:5672"
      - "15672:15672"
    environment:
      RABBITMQ_DEFAULT_USER: ${RABBITMQ_DEFAULT_USER:-ascension}
      RABBITMQ_DEFAULT_PASS: ${RABBITMQ_DEFAULT_PASS:-ascension}
    volumes:
      - rabbitmq_data:/var/lib/rabbitmq
    networks:
      - ascension-network
    healthcheck:
      test: ["CMD", "rabbitmq-diagnostics", "-q", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  postgresql:
    build: ./apps/server/postgres
    image: ${IMAGE_PREFIX:-ghcr.io/ascension-eip}/ascension-postgres:latest
    container_name: ascension-postgres
    restart: unless-stopped
    ports:
      - "${POSTGRES_PORT:-5432}:5432"
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-ascension}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-ascension}
      POSTGRES_DB: ${POSTGRES_DB:-ascension}
    volumes:
      - postgres_data:/var/lib/postgresql
    networks:
      - ascension-network
    healthcheck:
      test:
        [
          "CMD-SHELL",
          "pg_isready -U ${POSTGRES_USER:-ascension} -d ${POSTGRES_DB:-ascension}",
        ]
      interval: 10s
      timeout: 5s
      retries: 5

  server:
    build: ./apps/server
    container_name: ascension-server
    restart: unless-stopped
    profiles:
      - prod
    ports:
      - "${PORT:-8080}:8080"
    env_file: .env
    environment:
      - POSTGRES_HOST=postgresql
      - RABBITMQ_HOST=rabbitmq
      - MINIO_ENDPOINT=http://rustfs:${MINIO_PORT:-9000}
    networks:
      - ascension-network
    depends_on:
      postgresql:
        condition: service_healthy
      rabbitmq:
        condition: service_healthy
      rustfs:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "wget", "-q", "--spider", "http://localhost:8080/healthz"]
      interval: 10s
      timeout: 5s
      retries: 3

  ai-worker:
    build: ./apps/ai
    container_name: ascension-ai-worker
    restart: unless-stopped
    profiles:
      - prod
    env_file: .env
    environment:
      - POSTGRES_HOST=postgresql
      - POSTGRES_DB_URL=postgres://${POSTGRES_USER:-ascension}:${POSTGRES_PASSWORD:-ascension}@postgresql:${POSTGRES_PORT:-5432}/${POSTGRES_DB:-ascension}
      - RABBITMQ_HOST=rabbitmq
      - RUSTFS_ENDPOINT=http://rustfs:${MINIO_PORT:-9000}
      - RUSTFS_ACCESS_KEY=${MINIO_ID:-ascension}
      - RUSTFS_SECRET_KEY=${MINIO_SECRET:-ascension}
    networks:
      - ascension-network
    depends_on:
      postgresql:
        condition: service_healthy
      rabbitmq:
        condition: service_healthy
      rustfs:
        condition: service_healthy

volumes:
  rustfs_data:
  postgres_data:
  rabbitmq_data:

networks:
  ascension-network:
    name: ascension-network
```

---

## Database Migrations

### Create New Migration

Create `.up.sql` and `.down.sql` migration files under `apps/server/migrations/` manually, or use `golang-migrate` CLI:

```bash
migrate create -ext sql -dir apps/server/migrations -seq <migration_name>

```

This creates `apps/server/migrations/<seq>_<migration_name>.up.sql` and `apps/server/migrations/<seq>_<migration_name>.down.sql`.

Example migration:

```sql
-- migrations/20260212000001_initial_schema.sql

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    subscription_tier VARCHAR(50) DEFAULT 'freemium'
);

-- Videos table
CREATE TABLE videos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    storage_url TEXT NOT NULL,
    duration_seconds INTEGER,
    file_size_bytes BIGINT,
    uploaded_at TIMESTAMP DEFAULT NOW(),
    saved BOOLEAN DEFAULT FALSE,
    expires_at TIMESTAMP
);

-- Analyses table
CREATE TABLE analyses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    video_id UUID REFERENCES videos(id) ON DELETE CASCADE,
    status VARCHAR(50) DEFAULT 'pending',
    result_json JSONB,
    processing_time_ms INTEGER,
    created_at TIMESTAMP DEFAULT NOW(),
    completed_at TIMESTAMP
);

-- Indexes
CREATE INDEX idx_videos_user_id ON videos(user_id);
CREATE INDEX idx_videos_expires_at ON videos(expires_at) WHERE saved = FALSE;
CREATE INDEX idx_analyses_video_id ON analyses(video_id);
CREATE INDEX idx_analyses_status ON analyses(status);

```

Migrations run automatically on server startup. You can also view logs to see if migrations applied successfully:

```bash
docker-compose logs server

```

---

## Testing the Stack

### 1\. Health Check

```bash
curl -i http://localhost:8080/healthz
# Expected: HTTP/1.1 204 No Content

```

### 2\. User Registration

```bash
curl -X POST http://localhost:8080/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "first_name": "Test",
    "last_name": "User",
    "username": "testuser",
    "email": "test@example.com",
    "password": "SecurePass123!"
  }'

```

### 3\. Login

```bash
curl -X POST http://localhost:8080/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "identifier": "test@example.com",
    "password": "SecurePass123!"
  }'

```

Save the returned `access_token` and `refresh_token` for subsequent requests.

### 4\. Request Upload URL

```bash
curl -X GET "http://localhost:8080/v1/videos/upload-url?content_type=video/mp4&size=102400" \
  -H "Authorization: Bearer <your_token>"

```

### 5\. Upload Video (Direct to RustFS)

Use the presigned `upload_url` from the previous step:

```bash
curl -X PUT "<upload_url>" \
  --upload-file /path/to/your/video.mp4 \
  -H "Content-Type: video/mp4"

```

### 6\. Notify Upload Complete

```bash
curl -X PUT http://localhost:8080/v1/videos/upload-done/<video_id> \
  -H "Authorization: Bearer <your_token>"

```

### 7\. Start Analysis

```bash
curl -X POST http://localhost:8080/v1/analysis \
  -H "Authorization: Bearer <your_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "video_id": "<video_id_from_step_4>",
    "type": "2d",
    "visibility": "private"
  }'

```

### 8\. Poll for Results

```bash
curl http://localhost:8080/v1/analysis/<analysis_id> \
  -H "Authorization: Bearer <your_token>"

```

---

## Common Development Tasks

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f server
docker-compose logs -f ai-worker
docker-compose logs -f postgresql

```

### Restart Services

```bash
docker-compose restart server
docker-compose restart ai-worker

```

### Clean Database

```bash
docker-compose down -v  # WARNING: Deletes all data
docker-compose up -d

```

### Access PostgreSQL

```bash
docker-compose exec postgresql psql -U ascension -d ascension

```

```sql
-- Common queries
SELECT * FROM users;
SELECT * FROM videos ORDER BY uploaded_at DESC LIMIT 10;
SELECT * FROM analyses WHERE status = 'success';

```

### Access RabbitMQ Management UI

Open browser: [http://localhost:15672](http://localhost:15672)

Login:

- Username: `ascension`
- Password: `ascension` (`RABBITMQ_DEFAULT_USER` and `RABBITMQ_DEFAULT_PASS`)

Key views:

- **Queues**: Monitor `poses.detect` and `poses.advice`, and the dead-letter queues `poses.detect.dlq` and `poses.advice.dlq` (failed jobs and invalid payloads end there)
- **Connections**: Check active connections from API and workers
- **Exchanges**: View `events` (topic) and `events.dlx` (direct)

### Access RustFS Console

Open browser: [http://localhost:9001](http://localhost:9001)

Login (the values of `MINIO_ID` and `MINIO_SECRET`, passed to RustFS by Docker Compose):

- Username: `ascension`
- Password: `ascension`

---

## GPU Setup (Optional)

For faster AI processing, enable GPU support.

### Prerequisites

1. **NVIDIA GPU** with CUDA support
2. **NVIDIA Drivers** (latest)
3. **NVIDIA Container Toolkit**

```bash
# Install NVIDIA Container Toolkit
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-docker.list

sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker

```

### Enable GPU in Docker Compose

Uncomment the GPU section in `docker-compose.yml`:

```yaml
worker:
  # ... other config ...
  deploy:
    resources:
      reservations:
        devices:
          - driver: nvidia
            count: 1
            capabilities: [gpu]
```

### Verify GPU Access

```bash
docker-compose exec worker python -c "import torch; print(torch.cuda.is_available())"
# Should print: True

```

---

## Troubleshooting

### Port Already in Use

```bash
# Find process using port
lsof -i :8080

# Kill process
kill -9 <PID>

```

### Database Connection Refused

```bash
# Check if database is ready
docker-compose logs db

# Restart database
docker-compose restart db

```

### Worker Not Processing Jobs

```bash
# Check worker logs
docker-compose logs ai-worker

# Verify RabbitMQ connection
docker-compose exec ai-worker uv run python -c "import pika; c = pika.BlockingConnection(pika.ConnectionParameters('rabbitmq')); print('Connected'); c.close()"

```

Common causes:

- The worker exits with code 1 at startup when PostgreSQL, RustFS or RabbitMQ cannot be reached, or when the bucket `videos` does not exist.
- `PRECONDITION_FAILED` on `poses.detect` or `poses.advice`: the queues were created by an older version without the dead-letter arguments. Delete them in the RabbitMQ management UI (without touching the volumes); the worker recreates them.
- Nothing arrives: the Go server still publishes on `vision.skeleton`, which the worker does not consume. Use `producer.py` until the server is updated.
- An analysis stays `pending`: its payload was invalid and went to `<queue>.dlq` without any status.
- Database errors on `status` or `hints`: the migrations `20261030200000` and `20261030200100` are not applied.

### RustFS Not Accessible

```bash
# Check RustFS logs
docker-compose logs rustfs

# Check the health endpoint
curl -f http://localhost:9000/health

```

The bucket `videos` is created by the Go server at startup (or by `producer.py seed`). The worker never creates it and fails at startup if it is missing.

### Flutter Can't Connect to API

**Issue**: Connection refused

**Fix**: Update API endpoint based on platform:

- **iOS Simulator**: Use `http://127.0.0.1:8080` or `http://localhost:8080`
- **Android Emulator**: Use `http://10.0.2.2:8080`
- **Physical Device**: Use computer's local network IP (e.g., `http://192.168.1.100:8080`)

---

## Performance Optimization

### Development Mode

For faster iteration during development:

1. **Hot Reload for Go**: You can run `moon run server:dev` which executes the Gin application natively, or use standard tools like compiledaemon or air if you choose to set them up.

   Or via moon:

   ```bash
   moon run server:dev

   ```

2. **Python Auto-reload**:

   ```bash
   cd apps/ai
   uv run python -m pip install watchdog
   uv run watchmedo auto-restart --patterns="*.py" --recursive -- uv run worker

   ```

   Or via moon:

   ```bash
   moon run ai:dev

   ```

3. **Reduce Model Size**: Use quantized models for faster inference during development.

---

## Next Steps

- Read [API Gateway Documentation](../components/api-gateway.md)
- Review [AI Workers Implementation](../components/ai-workers.md)
- Understand [Video Analysis Workflow](../workflows/video-analysis-flow.md)

---

**Last Updated**: 2026-10-30 **Maintainer**: Ascension Development Team
