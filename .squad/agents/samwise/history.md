# Samwise — History

## Project Context
**Ascension** — Climbing video analysis platform. Docker Compose orchestrates local dev (MinIO, RabbitMQ, PostgreSQL, AI worker). Deployment targets: Hetzner VPS (staging) → dedicated servers/Kubernetes (production). GitHub Actions for CI/CD. Monitoring with Prometheus + Grafana + Loki. User: Gianni TUERO.

## Learnings

### 2026-03-02: Squad PR Review Workflow
- Created `.github/workflows/squad-pr-review.yml` — auto-routes PRs to squad agents by analyzing changed file paths.
- Routing: `apps/ai/` → gandalf, `apps/server/` → boromir, `apps/mobile/` → legolas, `.github/`/docker → samwise, `docs/` → bilbo, migrations/queue/storage → gimli, cross-domain (>2 agents) → aragorn.
- Labels are auto-created on first use (color `9B8FCC` matches existing squad palette from `sync-squad-labels.yml`).
- Stale labels are removed on PR update (synchronize) to keep routing accurate.
- Comment is upserted (not duplicated) using an HTML marker `<!-- squad-pr-review -->`.
- Created `CODEOWNERS` at repo root mapping paths to `@Ascension-EIP/{team}` org teams.
- Pattern: use `actions/github-script@v7` for self-contained labeling + commenting — no external actions needed.
- Concurrency group prevents parallel runs on the same PR number.
