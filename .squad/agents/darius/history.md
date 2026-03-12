# Darius — History

## Project Context
**Ascension** — Climbing video analysis platform. Documentation in docs/ with structure: developer_guide/ (ai/, architecture/, mobile/, server/), git/ (commit/branch/actions standards), guidelines/ (markdown), ai/ (pre-prompts), resources/, rncp/, drafts/. Follows versioned headers (Last updated, Version, Authors, Status). User: Gianni TUERO.

## Learnings

### 2026-03-11: AI consumer entrypoint documentation renamed to worker
- Updated AI and architecture documentation to replace `apps/ai/consumer.py` references with `apps/ai/worker.py`.
- Standardized visible wording from `consumer` to `worker` where the docs referred to the per-queue Python entrypoint naming.
- Key files synced: `docs/developer_guide/ai/README.md`, `docs/developer_guide/architecture/system-overview.md`, `docs/developer_guide/architecture/monorepo-guide.md`, `docs/developer_guide/architecture/deployment/development.md`, `docs/ai/pre-prompt-en.md`, `docs/ai/pre-prompt-fr.md`.

### 2026-03-03: AI docs aligned to moon prefix-based conda contract
- Confirmed `apps/ai/moon.yml` is prefix-based (`-p ./ai-env` and `conda run --prefix ./ai-env`) and should remain the source of truth.
- Updated `docs/developer_guide/ai/README.md` to remove named-env wording (`ascension-ai`) and align setup/run examples with `./ai-env`.
- Documented idempotent setup expectation for `moon run ai:setup` (`conda env create ... --force`) so refresh behavior matches task semantics.

### 2026-03-03: PR #70 Docs Review — Conda setup convention mismatch
- Performed a review-only pass on PR #70 focused on documentation clarity, accuracy, and maintainability.
- Identified an ambiguity between documentation and task runner commands: docs examples use `conda --name ascension-ai` while `apps/ai/moon.yml` executes with `--prefix ./ai-env`.
- Posted one consolidated PR review comment requesting a single canonical environment convention and aligned setup/run snippets.
- Noted that the requested artifact `apps/ai/README.md` does not exist in the repository; AI docs are currently centralized in `docs/developer_guide/ai/README.md`.

### 2026-03-03: AI Environment Documentation Migrated from venv to conda
- Updated AI setup and execution docs to use conda-based commands and environment lifecycle (`environment.yml` + `conda run`).
- Synchronized documentation examples with current moon tasks in `apps/ai/moon.yml`: `ai:setup`, `ai:install`, `ai:dev`, `ai:build`, `ai:lint`, `ai:test`.
- Replaced CI cache wording that referenced `apps/ai/venv` with conda-compatible cache language.
- Added explicit conda + moon local setup section in `docs/developer_guide/ai/README.md` and aligned RNCP docs wording from `requirements.txt` to `environment.yml` + `pyproject.toml`.

### 2026-03-02: CODEOWNERS File Created
- Arthur created `CODEOWNERS` at repo root for GitHub-native path-to-team mapping.
- Documentation paths (`docs/**`) now route to `@Ascension-EIP/docs` team for automated review assignment.
- Enables automatic review notifications for docs changes across the codebase.

### 2026-03-02: AI Layer Documentation Created
- Documented the `feat(ai): implement vision.skeleton pipeline` commit (consumer.py + pose_analysis.py).
- Created `docs/developer_guide/ai/README.md` — comprehensive AI worker docs covering:
  - Worker architecture and per-pipeline consumer pattern
  - `vision.skeleton` end-to-end flow with Mermaid sequence diagram
  - `pose_analysis` module: tracked landmarks, output format, angle computation
  - All required environment variables (RabbitMQ, MinIO, PostgreSQL)
  - General pipeline pattern for future pipelines (hold_detection, advice, ghost, training.program)
  - Error handling and RabbitMQ startup retry strategy
- Updated `docs/developer_guide/architecture/system-overview.md` — replaced the conceptual `AscensionWorker` pseudocode in the Layer 4 Worker Architecture section with the actual per-pipeline consumer pattern and implementation status table.
