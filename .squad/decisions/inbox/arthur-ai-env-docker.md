# Decision Proposal: AI env contract and Docker context hardening

- **Date:** 2026-03-03
- **Author:** Arthur (DevOps)
- **Scope:** `apps/ai/Dockerfile`, `apps/ai/.dockerignore`, `docker-compose.yml`

## Context
PR review identified drift risks between local AI setup and container/runtime configuration, and high Docker build-context weight from local artifacts in `apps/ai/`.

## Proposed Decision
1. Keep local conda environment contract on prefix path `./ai-env` as the single source for developer workflows (`moon` tasks/docs), without introducing lockfile work in this pass.
2. Keep Docker runtime on named conda env `ascension-ai` for now (safe/compatible with existing image flow).
3. Enforce `apps/ai/.dockerignore` to exclude local envs, heavy assets, caches, and build artifacts from AI image context.
4. For `ai-worker` compose config, prefer `.env` + `${VAR:-default}` fallbacks over hardcoded inline credentials.

## Rationale
- Preserves current local contract while avoiding broad migration scope.
- Reduces image build time/context size and accidental artifact inclusion.
- Lowers config drift across dev/staging/prod by centralizing overridable env values.

## Impact
- No application-code behavior change.
- Minimal, backward-compatible compose defaults retained.
- Safer baseline for future CI/deployment hardening.
