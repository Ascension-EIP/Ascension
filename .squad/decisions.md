# Decisions

## 2026-03-03: Declare AI worker runtime deps in pyproject (conda + pip flow)
**By:** Quentin (AI Dev)
**Context:** `apps/ai/moon.yml` installs Python packages with `conda run --name ascension-ai python -m pip install -e .[dev]`.
**Decision:** Runtime imports used by `apps/ai/consumer.py` must be declared in `apps/ai/pyproject.toml` under `[project.dependencies]`.
**Applied:** Added `boto3`, `pika`, and `psycopg2-binary`.
**Why:** `environment.yml` provisions Python + pip base only. Package resolution for the worker runtime happens in `pip install -e .[dev]`; undeclared imports trigger `ModuleNotFoundError` during `moon run ai:dev` on fresh setup.

## 2026-03-03: Standardize AI docs on conda-based moon workflow
**By:** Darius (Docs)
**Context:** `apps/ai/moon.yml` runs AI tasks through conda (`conda run --name ascension-ai ...`) with setup from `environment.yml`.
**Decision:** Documentation references for AI local setup and execution must use conda workflows, not venv-oriented paths or legacy Python dependency wording.
**Applied to:**
- AI setup steps in `docs/developer_guide/ai/README.md`
- Python stack/package wording in `docs/rncp/audit/stack-summary.md`
- Prototype dependency note in `docs/rncp/prototype-pool.md`
**Rationale:** Keeps onboarding docs aligned with executable moon tasks and avoids environment drift.

## 2026-03-02: AI Layer Documentation Created (Informational)
**By:** Darius (Docs)
**Triggered by:** feat(ai): implement vision.skeleton pipeline
**What:** Created `docs/developer_guide/ai/README.md` covering the consumer pattern, `vision.skeleton` pipeline flow, `pose_analysis` module output format, environment variables, and error handling strategy. Updated `docs/developer_guide/architecture/system-overview.md` — replaced conceptual `AscensionWorker` pseudocode in Layer 4 with the actual per-pipeline consumer pattern and implementation status table.
**Note:** No architectural decisions were made by Darius. This entry records documentation work only; all architectural decisions were made during the implementation phase by Quentin (AI Dev).

## 2026-03-02: vision.skeleton pipeline integration in consumer.py
**By:** Quentin (AI Dev)
**Date:** 2025-07-25
**What:** Implemented the full vision.skeleton pipeline flow in `apps/ai/consumer.py`.
**Why:** The consumer was a skeleton with placeholder comments. Needed to wire up S3 download, MediaPipe analysis, PostgreSQL persistence, and event publishing to make the pipeline functional end-to-end.
**How:**
- Single `on_message` callback handles the full job lifecycle: download → analyze → save → publish → ack.
- Uses `boto3` for MinIO/S3, `psycopg2` for PostgreSQL, `pika` for RabbitMQ.
- Connection retry loop (12 × 5s) for RabbitMQ startup races.
- Temp files cleaned in `finally` block. DB connections opened per-job and closed after.
- `ascension.events` topic exchange declared at startup for event publishing.
- Errors nack (requeue) + update analysis status to `failed` (best-effort).
- docker-compose.yml updated to pass MinIO and Postgres env vars to ai-worker.

**Impact:** Other pipelines (hold_detection, advice, ghost, training.program) should follow the same pattern — download, process, persist, publish, ack/nack.

## 2026-03-02: Squad PR Review Workflow
**By:** Arthur (DevOps)
**What:** Added automated PR review routing via `.github/workflows/squad-pr-review.yml` and a `CODEOWNERS` file at repo root.
**Why:** PRs touching multiple domains need the right squad agents reviewing the right parts. Manual labeling doesn't scale and is easy to forget.
**How:** Workflow triggers on `pull_request` (opened, synchronize, reopened). Analyzes changed files against a routing table and applies `squad:{agent}` labels. Posts/updates a summary comment showing which agents should review which files. `CODEOWNERS` provides GitHub-native auto-assignment to `@Ascension-EIP/{team}` org teams.
**Routing:** `apps/ai/` → quentin, `apps/server/` → renaud, `apps/mobile/` → romaric, `.github/`/docker → arthur, `docs/` → darius, migrations/queue/storage → alexandra, >2 domains → eric.
**Impact:** All squad agents now receive PR labels automatically; org admins must create GitHub teams for CODEOWNERS to activate.

## 2026-03-02: Team Formation
**By:** Gianni TUERO
**What:** Team created with 7 agents: Eric (Lead), Quentin (AI), Renaud (Backend), Romaric (Mobile), Arthur (DevOps), Alexandra (Infra), Darius (Docs). Named from Lord of the Rings universe.
**Why:** Matches project domains — AI pipelines, Rust API, Flutter mobile, Docker/deployment, RabbitMQ/PostgreSQL/MinIO infra, and documentation sync.

## 2026-03-02: No Auto-Commit
**By:** Gianni TUERO
**What:** Les agents ne doivent PAS faire de git commit automatiquement après chaque feature. Les commits sont gérés manuellement par l'utilisateur ou sur demande explicite.
**Why:** Préférence utilisateur — le contrôle des commits reste humain.
