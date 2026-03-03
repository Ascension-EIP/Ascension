# Arthur — History

## Project Context
**Ascension** — Climbing video analysis platform. Docker Compose orchestrates local dev (MinIO, RabbitMQ, PostgreSQL, AI worker). Deployment targets: Hetzner VPS (staging) → dedicated servers/Kubernetes (production). GitHub Actions for CI/CD. Monitoring with Prometheus + Grafana + Loki. User: Gianni TUERO.

## Learnings

### 2026-03-03: Moon setup idempotence hardening
- Updated `apps/ai/moon.yml` `setup` task to include `conda env create --force` while keeping the existing prefix-based target (`-p ./ai-env`) unchanged.

### 2026-03-03: AI env contract follow-up (surgical drift reduction)
- Kept local AI environment contract anchored on `apps/ai/moon.yml` prefix path (`./ai-env`) and avoided lockfile scope creep.
- Added `apps/ai/.dockerignore` to cut heavy local artifacts from Docker build context (`ai-env/`, `sam-3d-body/`, `__pycache__/`, `*.egg-info/`, plus standard Python/build caches).
- Reduced compose config drift risk by using `env_file: .env` with `${VAR:-default}` fallbacks for `ai-worker` instead of hardcoded credentials.
- Improved Docker rebuild behavior safely by copying `environment.yml`/`pyproject.toml` before full source copy while preserving named Docker conda env (`ascension-ai`).

### 2026-03-03: PR #70 DevOps Review (Conda AI setup)
- Reviewed PR #70 (`feat/ai-conda-setup`) with focus on Docker/compose/dev-env and CI implications.
- Main risk identified: `apps/ai/Dockerfile` switched to single-stage `continuumio/miniconda3` with `COPY . .` before dependency install and no `apps/ai/.dockerignore`, which can inflate build context and image size (notably local artifacts like `ai-env/`, caches, and auxiliary folders).
- Reproducibility risk identified: `environment.yml` pins only Python/pip while runtime dependencies in `pyproject.toml` are partially ranged; this can create drift between local builds and CI over time.
- Compose risk identified: `ai-worker` moved from `env_file` to hardcoded `environment` credentials, increasing chance of config drift across environments.
- Posted one PR review comment via GitHub CLI with one concrete follow-up: add `apps/ai/.dockerignore` immediately, then adopt a pinned dependency lock source used consistently by Docker and CI.

### 2026-03-02: Squad PR Review Workflow
- Created `.github/workflows/squad-pr-review.yml` — auto-routes PRs to squad agents by analyzing changed file paths.
- Routing: `apps/ai/` → quentin, `apps/server/` → renaud, `apps/mobile/` → romaric, `.github/`/docker → arthur, `docs/` → darius, migrations/queue/storage → alexandra, cross-domain (>2 agents) → eric.
- Labels are auto-created on first use (color `9B8FCC` matches existing squad palette from `sync-squad-labels.yml`).
- Stale labels are removed on PR update (synchronize) to keep routing accurate.
- Comment is upserted (not duplicated) using an HTML marker `<!-- squad-pr-review -->`.
- Created `CODEOWNERS` at repo root mapping paths to `@Ascension-EIP/{team}` org teams.
- Pattern: use `actions/github-script@v7` for self-contained labeling + commenting — no external actions needed.
- Concurrency group prevents parallel runs on the same PR number.
