# Decisions

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
