---
title: Documentation Index
description: Navigation entrypoint for Ascension docs (GitHub Wiki sync)
published: true
date: 2026-03-12T00:00:00.000Z
tags:
  - index
  - wiki
editor: markdown
dateCreated: 2026-03-12T00:00:00.000Z
---

# Ascension — Documentation Index

This page is the central **table of contents** for the `docs/` folder (GitHub Wiki sync / wiki navigation).

## Hubs (Nouvelle navigation)

L'arborescence a été restructurée. Voici les points d'entrée pour chaque domaine :

- [00 — Start here](./00-start-here/index.md)
- [10 — Product](./10-product/index.md)
- [20 — Engineering](./20-engineering/index.md)
- [30 — Operations](./30-operations/index.md)
- [40 — Management](./40-management/index.md)
- [50 — Compliance](./50-compliance/index.md)
- [90 — Drafts](./90-drafts/index.md)
- [99 — Resources](./99-resources/index.md)

## Publication / Wiki

Documentation updates under `docs/` are published to the GitHub Wiki via a workflow that generates a flattened set of pages and pushes them.

- Workflow: `.github/workflows/docs-to-wiki.yml`
- Generator script: `.github/scripts/generate_wiki`

⚠️ Note: Markdown files named `README.md` under `docs/` are **not exported** by the generator (it excludes by basename). If you want a folder entrypoint to appear in the Wiki, prefer an `index.md` at that folder level.
