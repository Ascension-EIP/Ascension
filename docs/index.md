> **Last updated:** 16th March 2026  
> **Version:** 1.1  
> **Authors:** Nicolas  
> **Status:** Done  
> {.is-success}

---

# Ascension Documentation Index

## Table of Contents

- [Ascension Documentation Index](#ascension-documentation-index)
  - [Documentation Hubs](#documentation-hubs)
  - [Wiki Publication](#wiki-publication)

---

## Documentation Hubs

This page is the main entry point for all project documentation.

- [00 — Start Here](./00-start-here/index.md)
- [10 — Product](./10-product/index.md)
- [20 — Engineering](./20-engineering/index.md)
- [30 — Compliance](./30-compliance/index.md)
- [40 — Management](./40-management/index.md)
- [50 — Resources](./50-resources/index.md)
- [90 — Drafts](./90-drafts/index.md)

---

## Wiki Publication

Documentation under `docs/` is synchronized to the project Wiki.

- Workflow: `.github/workflows/docs-to-wiki.yml`
- Generator: `.github/scripts/generate_wiki`

Markdown files named `README.md` under `docs/` are excluded by the generator.
Use `index.md` as the entry page for directories that must appear in the Wiki.
