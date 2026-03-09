# Darius Decision Inbox — AI Env Docs Sync (2026-03-03)

## Context
`apps/ai/moon.yml` is the executable source of truth for local AI workflows and uses a prefix-based Conda contract (`-p ./ai-env`, `conda run --prefix ./ai-env ...`).

## Team-Relevant Decision
Documentation must mirror Moon’s prefix-based environment contract and idempotent setup behavior.

- Use `./ai-env` (not a named env) in all AI setup/run snippets tied to Moon tasks.
- Describe `moon run ai:setup` as safe to re-run for refreshes because it executes `conda env create ... --force` against the same prefix path.

## Why
Keeping docs aligned to executable task definitions avoids onboarding drift, reduces setup failures, and preserves reproducible local behavior across contributors.

## Applied
Updated `docs/developer_guide/ai/README.md` to replace `ascension-ai` references with `./ai-env` and to document idempotent setup expectations.
