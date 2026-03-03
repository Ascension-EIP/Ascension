# Darius — History

## Project Context
**Ascension** — Climbing video analysis platform. Documentation in docs/ with structure: developer_guide/ (ai/, architecture/, mobile/, server/), git/ (commit/branch/actions standards), guidelines/ (markdown), ai/ (pre-prompts), resources/, rncp/, drafts/. Follows versioned headers (Last updated, Version, Authors, Status). User: Gianni TUERO.

## Learnings

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
