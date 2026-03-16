# Eric — History

## Project Context
**Ascension** — Climbing video analysis platform. Flutter mobile, Rust/Axum API, Python AI workers (PyTorch, MediaPipe, OpenCV), RabbitMQ messaging, PostgreSQL + MinIO/S3 persistence. Docker Compose for local dev. User: Gianni TUERO.

## Learnings

### 2026-03-16: RNCP Block 1 M1 evidence posture — strongest assets are audit/specs, weakest are accessibility-proof formalization and oral packaging
- Completed a repository-wide evidence sweep for Block 1 M1 observables (O1→O11).
- Strength identified: audit and architecture/specification material is already substantial (`context-audit-compliance.md`, `tech-func-specs.md`, API/DB specs, code-level anchors in `apps/server/` and `apps/ai/`).
- Main gaps are documentary proof quality rather than implementation volume: raw user-research artifacts (O1), explicit accessibility traceability from needs/specs to tests (O2/O6/O7), and oral-ready per-observable narration assets (O11).
- Operational recommendation for docs coordination: prioritize O2/O7/O11 first, then add a single reusable traceability matrix to de-risk O1/O5/O6 simultaneously.

### 2026-03-03: PR #70 architecture review — Conda migration coherence risk
- Reviewed PR #70 (`feat/ai-conda-setup` -> `dev`) with focus on runtime setup architecture.
- Strength: AI setup converges on Conda across Docker and moon tasks, improving reproducibility.
- Risk identified: environment identity is inconsistent (`--prefix ./ai-env` vs named `ascension-ai`) across moon, Docker, and docs.
- Recommendation issued on PR: define one canonical environment contract and validate it with a CI smoke path.

### 2026-03-02: Squad PR Review Workflow Deployed
- Arthur created `.github/workflows/squad-pr-review.yml` for automated PR routing.
- All PRs now auto-labeled with `squad:{agent}` based on changed file paths.
- Cross-domain PRs (>2 agents) automatically assigned to Eric for architectural review.
- Companion `CODEOWNERS` file ensures `@Ascension-EIP/{team}` org teams auto-requested for review.

### 2026-03-03: Ralph review feedback policy tightened (suggestions-first)
- Updated Squad coordinator policy for Ralph when `CHANGES_REQUESTED` appears on PRs.
- Ralph now asks concerned squad members to propose clear fix suggestions (patch/plan) similar to Copilot suggestion workflow.
- Guardrails made explicit: no automatic fix implementation, no auto-commit, no auto-push.
- Continuous Ralph monitoring loop remains unchanged; only review-feedback handling behavior was adjusted.
