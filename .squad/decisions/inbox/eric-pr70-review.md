# Eric Decision Inbox — PR #70 (2026-03-03)

## Context
PR #70 (`feat/ai-conda-setup` -> `dev`) introduces Conda-based AI setup across `apps/ai/Dockerfile`, `apps/ai/environment.yml`, and `apps/ai/moon.yml`, with related documentation updates.

## Team-Relevant Decision
Adopt a **single canonical AI environment identity contract** across all execution surfaces.

- Choose one model and enforce it everywhere:
  - either named env (e.g., `ascension-ai`),
  - or prefix-based env path (e.g., `./ai-env`).
- Apply uniformly in moon tasks, Docker image build/runtime entrypoint, and developer docs.

## Why
Mixed contracts create cross-domain drift risk (DevOps scripts, onboarding docs, and AI task runners diverge), which can produce non-reproducible local/CI behavior.

## Required Follow-up
Add one CI smoke workflow that executes the canonical path end-to-end:
1. environment create
2. editable install
3. consumer startup sanity check
