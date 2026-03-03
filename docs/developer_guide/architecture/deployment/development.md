> **Last updated:** 18th February 2026  
> **Version:** 2.0  
> **Authors:** Gianni TUERO  
> **Status:** Done  
> {.is-success}

---

# Development Environment Setup

---

## Table of Contents

- [Overview](#overview)
- [Architecture Diagram](#architecture-diagram)
- [Prerequisites](#prerequisites)
  - [Required Software](#required-software)
  - [Optional Tools](#optional-tools)
- [Project Structure](#project-structure)
- [Step-by-Step Setup](#step-by-step-setup)
  - [1. Install moon](#1-install-moon)
  - [2. Clone Repository](#2-clone-repository)


---

## Overview

The development environment runs all services on a single machine using Docker Compose. This setup is optimized for rapid iteration and local testing.

---

## Architecture Diagram

```mermaid
graph TB
    subgraph "Developer Machine"
        subgraph "Docker Compose Network"
            API[Rust API :8080]
            DB[(PostgreSQL :5432)]
            RabbitMQ[(RabbitMQ :5672/:15672)]
            MinIO[MinIO :9000/:9001]
            Worker[Python AI Worker]
        end

        Flutter[Flutter App<br/>iOS Simulator/Android Emulator]
    end

    Flutter -->|HTTP/WS| API
    Flutter -->|Direct Upload| MinIO
    API --> DB
    API --> RabbitMQ
    Worker --> RabbitMQ
    Worker --> MinIO
    Worker --> DB

    style API fill:#e1f5ff
    style Worker fill:#fff4e1
    style DB fill:#f0f0f0
    style RabbitMQ fill:#ffe1e1
    style MinIO fill:#e1ffe1
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

3. **Rust Toolchain** (1.93+)

   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
   rustup default stable
   ```

4. **Flutter SDK** (3.16+)

   ```bash
   # macOS
   brew install flutter

   # Or download from https://docs.flutter.dev/get-started/install
   ```

5. **Python** (3.10+)

   ```bash
   # macOS
   brew install python@3.11

   # Linux
   sudo apt-get install python3.11 python3.11-venv
   ```

### Optional Tools

- **pgAdmin** or **DBeaver**: Database GUI
- **RabbitMQ Management UI**: Built-in at http://localhost:15672
- **Postman** or **Insomnia**: API testing

---

## Project Structure

The project uses a **monorepo managed with [moonrepo](https://moonrepo.dev)**. All services are located under `apps/` in the main `Ascension` repository:

```
Ascension/                      # Monorepo root
├── .moon/
│   ├── workspace.yml           # Projects: server, ai, mobile
│   └── toolchain.yml           # Pinned toolchain versions
├── docker-compose.yml          # Orchestration of all services
├── .env.example                # Environment variables template
├── README.md
│
└── apps/
    ├── server/                 # Rust API server
    │   ├── moon.yml
    │   ├── Cargo.toml
    │   ├── Dockerfile
    │   └── src/
    │       └── main.rs
    │
    ├── ai/                     # Python AI workers
    │   ├── moon.yml
    │   ├── requirements.txt
    │   ├── Dockerfile
    │   └── main.py
    │
    └── mobile/                 # Flutter mobile app
        ├── moon.yml
        ├── pubspec.yaml
        └── lib/
            ├── main.dart
```

**Why moonrepo instead of submodules?**

- Single `git clone` — everything is already in the repo
- Unified task runner with caching (`moon run server:dev`)
- Toolchain versions (Rust, Python) pinned in `.moon/toolchain.yml`
- Affected-only CI builds

---

## Step-by-Step Setup

### 1. Install moon

```bash
# macOS / Linux
curl -fsSL https://moonrepo.dev/install/moon.sh | bash

# Make sure ~/.moon/bin is in your PATH
export PATH="$HOME/.moon/bin:$PATH"

# Verify
moon --version
```

### 2. Clone Repository

```bash
# Simple clone — no --recursive needed
git clone https://github.com/Ascension-EIP/Ascension.git
cd Ascension
```

**Verify the structure:**

```bash
ls apps/
# You should see: server/  ai/  mobile/

# List moon projects
moon project --list
### 3. Environment Configuration

Create `.env` file from template:

```bash
cp .env.example .env
```

Edit `.env`:

```bash
# Database
POSTGRES_USER=ascension
POSTGRES_PASSWORD=dev_password_change_in_prod
POSTGRES_DB=ascension_dev
DATABASE_URL=postgresql://ascension:dev_password_change_in_prod@db:5432/ascension_dev

# RabbitMQ
RABBITMQ_URL=amqp://guest:guest@rabbitmq:5672

# MinIO (S3-compatible storage)
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=minioadmin
MINIO_ENDPOINT=http://minio:9000
MINIO_BUCKET=ascension-videos

# API
API_HOST=0.0.0.0
API_PORT=8080
JWT_SECRET=your-secret-key-generate-a-secure-one
RUST_LOG=debug

# AI Workers
WORKER_CONCURRENCY=2
MODEL_CACHE_DIR=/tmp/models

# Environment
ENVIRONMENT=development
```

### 4. Launch Infrastructure

Start all services:

```bash
docker-compose up -d
```

This launches:

- PostgreSQL (port 5432)
- RabbitMQ (port 5672 for AMQP, 15672 for management UI)
- MinIO (port 9000 for API, 9001 for UI)

Verify services are running:

```bash
docker-compose ps
```

Expected output:

```
NAME                    SERVICE             STATUS
ascension-db-1          db                  running
ascension-rabbitmq-1    rabbitmq            running
ascension-minio-1       minio               running
```

### 5. Initialize Database

Run migrations:

```bash
# From apps/server directory
cd apps/server
cargo install sqlx-cli --no-default-features --features postgres
sqlx migrate run
```

Seed development data (optional):

```bash
cargo run --bin seed
```

**Note**: Database migrations are located in `apps/server/migrations/`

### 6. Build and Run API Server

#### Option A: Using Docker (Recommended)

```bash
# From Ascension root directory
docker-compose up api -d
```

#### Option B: Using moon (Faster Iteration)

```bash
# From anywhere in the repo
moon run server:dev
```

#### Option C: Direct cargo

```bash
cd apps/server
cargo run
```

Verify API is running:

```bash
curl http://localhost:8080/health
# Expected: {"status":"ok","database":"connected","rabbitmq":"connected"}
```

### 7. Set Up AI Workers

#### Install Dependencies via moon

```bash
moon run ai:install
```

Or manually:

```bash
cd apps/ai
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

#### Download ML Models

```bash
python scripts/download_models.py
```

This downloads:

- MediaPipe Pose model (~25MB)
- Hold detection CNN weights (~150MB)

#### Run Worker

```bash
# Via moon (recommended)
moon run ai:dev

# Or directly
cd apps/ai && venv/bin/python main.py
```

Or using Docker:

```bash
docker-compose up worker -d
```

**Note**: For GPU support, see [GPU Setup](#gpu-setup-optional) below.

### 8. Configure Flutter App

#### Update API Endpoint

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

#### Install Dependencies

```bash
# Via moon
moon run mobile:install

# Or directly
cd apps/mobile
flutter pub get
```

#### Run App

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
version: "3.8"

services:
  # PostgreSQL Database
  db:
    image: postgres:15-alpine
    container_name: ascension-db
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./apps/server/migrations/init.sql:/docker-entrypoint-initdb.d/init.sql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5

  # RabbitMQ (Message Broker)
  rabbitmq:
    image: rabbitmq:3.12-management-alpine
    container_name: ascension-rabbitmq
    ports:
      - "5672:5672"
      - "15672:15672"
    volumes:
      - rabbitmq_data:/var/lib/rabbitmq
    healthcheck:
      test: ["CMD", "rabbitmq-diagnostics", "-q", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  # MinIO (S3-compatible storage)
  minio:
    image: minio/minio:latest
    container_name: ascension-minio
    command: server /data --console-address ":9001"
    environment:
      MINIO_ROOT_USER: ${MINIO_ROOT_USER}
      MINIO_ROOT_PASSWORD: ${MINIO_ROOT_PASSWORD}
    ports:
      - "9000:9000" # API
      - "9001:9001" # Web UI
    volumes:
      - minio_data:/data
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
      interval: 30s
      timeout: 20s
      retries: 3

  # MinIO Bucket Initialization
  minio-init:
    image: minio/mc:latest
    depends_on:
      - minio
    entrypoint: >
      /bin/sh -c "
      /usr/bin/mc alias set myminio http://minio:9000 ${MINIO_ROOT_USER} ${MINIO_ROOT_PASSWORD};
      /usr/bin/mc mb myminio/${MINIO_BUCKET} --ignore-existing;
      /usr/bin/mc anonymous set download myminio/${MINIO_BUCKET};
      exit 0;
      "

  # Rust API Server (from apps/server/)
  api:
    build:
      context: ./apps/server
      dockerfile: Dockerfile
      target: development
    container_name: ascension-api
    environment:
      DATABASE_URL: ${DATABASE_URL}
      RABBITMQ_URL: ${RABBITMQ_URL}
      MINIO_ENDPOINT: ${MINIO_ENDPOINT}
      MINIO_BUCKET: ${MINIO_BUCKET}
      MINIO_ROOT_USER: ${MINIO_ROOT_USER}
      MINIO_ROOT_PASSWORD: ${MINIO_ROOT_PASSWORD}
      JWT_SECRET: ${JWT_SECRET}
      RUST_LOG: ${RUST_LOG}
    ports:
      - "8080:8080"
    volumes:
      - ./apps/server:/app
      - cargo_cache:/usr/local/cargo
    depends_on:
      db:
        condition: service_healthy
      rabbitmq:
        condition: service_healthy
      minio:
        condition: service_healthy
    restart: unless-stopped

  # Python AI Worker (from apps/ai/)
  worker:
    build:
      context: ./apps/ai
      dockerfile: Dockerfile
    container_name: ascension-worker
    environment:
      DATABASE_URL: ${DATABASE_URL}
      RABBITMQ_URL: ${RABBITMQ_URL}
      MINIO_ENDPOINT: ${MINIO_ENDPOINT}
      MINIO_BUCKET: ${MINIO_BUCKET}
      MINIO_ROOT_USER: ${MINIO_ROOT_USER}
      MINIO_ROOT_PASSWORD: ${MINIO_ROOT_PASSWORD}
      WORKER_CONCURRENCY: ${WORKER_CONCURRENCY}
      MODEL_CACHE_DIR: ${MODEL_CACHE_DIR}
    volumes:
      - ./apps/ai:/app
      - model_cache:/tmp/models
    depends_on:
      - rabbitmq
      - minio
      - db
    restart: unless-stopped
    # Uncomment for GPU support
    # deploy:
    #   resources:
    #     reservations:
    #       devices:
    #         - driver: nvidia
    #           count: 1
    #           capabilities: [gpu]

volumes:
  postgres_data:
  rabbitmq_data:
  minio_data:
  cargo_cache:
  model_cache:
```

---

## Database Migrations

### Create New Migration

```bash
cd server
sqlx migrate add <migration_name>
```

This creates `server/migrations/<timestamp>_<migration_name>.sql`

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

### Run Migrations

```bash
cd apps/server
sqlx migrate run
```

### Rollback Migration

```bash
cd apps/server
sqlx migrate revert
```

---

## Testing the Stack

### 1. Health Check

```bash
curl http://localhost:8080/health
```

### 2. User Registration

```bash
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "SecurePass123!"
  }'
```

### 3. Login

```bash
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "SecurePass123!"
  }'
```

Save the returned `access_token` for subsequent requests.

### 4. Request Upload URL

```bash
curl -X POST http://localhost:8080/api/v1/analysis/request-upload \
  -H "Authorization: Bearer <your_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "file_name": "climb.mp4",
    "content_type": "video/mp4"
  }'
```

### 5. Upload Video (Direct to MinIO)

Use the presigned URL from step 4:

```bash
curl -X PUT "<presigned_url>" \
  --upload-file /path/to/your/video.mp4 \
  -H "Content-Type: video/mp4"
```

### 6. Start Analysis

```bash
curl -X POST http://localhost:8080/api/v1/analysis/start \
  -H "Authorization: Bearer <your_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "video_id": "<video_id_from_step_4>"
  }'
```

### 7. Poll for Results

```bash
curl http://localhost:8080/api/v1/analysis/<job_id> \
  -H "Authorization: Bearer <your_token>"
```

---

## Common Development Tasks

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f api
docker-compose logs -f worker
```

### Restart Services

```bash
docker-compose restart api
docker-compose restart worker
```

### Clean Database

```bash
docker-compose down -v  # WARNING: Deletes all data
docker-compose up -d
```

### Access PostgreSQL

```bash
docker-compose exec db psql -U ascension -d ascension_dev
```

```sql
-- Common queries
SELECT * FROM users;
SELECT * FROM videos ORDER BY uploaded_at DESC LIMIT 10;
SELECT * FROM analyses WHERE status = 'completed';
```

### Access RabbitMQ Management UI

Open browser: http://localhost:15672

Login:

- Username: `guest`
- Password: `guest`

Key views:

- **Queues**: Monitor `analysis_jobs` queue depth
- **Connections**: Check active connections from API and workers
- **Exchanges**: View `ascension.analysis` and `ascension.events`

### Access MinIO UI

Open browser: http://localhost:9001

Login:

- Username: `minioadmin`
- Password: `minioadmin`

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
docker-compose logs worker

# Verify RabbitMQ connection
docker-compose exec worker python -c "import pika; c = pika.BlockingConnection(pika.ConnectionParameters('rabbitmq')); print('Connected'); c.close()"
```

### MinIO Not Accessible

```bash
# Check MinIO logs
docker-compose logs minio

# Verify bucket creation
docker-compose exec minio mc ls myminio/
```

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

1. **Hot Reload for Rust** (using cargo-watch):

   ```bash
   cargo install cargo-watch
   cd apps/server && cargo watch -x run
   ```

   Or via moon:

   ```bash
   moon run server:dev
   ```

2. **Python Auto-reload**:

   ```bash
   cd apps/ai
   venv/bin/pip install watchdog
   watchmedo auto-restart --patterns="*.py" --recursive venv/bin/python main.py
   ```

   Or via moon:

   ```bash
   moon run ai:dev
   ```

3. **Reduce Model Size**:
   Use quantized models for faster inference during development.

---

## Next Steps

- Read [API Gateway Documentation](../components/api-gateway.md)
- Review [AI Workers Implementation](../components/ai-workers.md)
- Understand [Video Analysis Workflow](../workflows/video-analysis-flow.md)

---

**Last Updated**: 2026-02-12
**Maintainer**: Ascension Development Team
