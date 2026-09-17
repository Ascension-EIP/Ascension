---
name: update-docs
description: "AI Command: Update Documentation (/update-docs)"
globs: ["*.md"]
alwaysApply: false
---

> **Last updated:** 3rd September 2026  
> **Version:** 1.0  
> **Authors:** Nicolas TORO  
> **Original language:** English  
> **Status:** Done  
> {.is-success}

---

# AI Command: Update Documentation (`/update-docs`)

Protocol for inspecting modified features, architecture, or APIs and updating all relevant documentation files accordingly.

---

## Table of Contents

- [AI Command: Update Documentation (`/update-docs`)](#ai-command-update-documentation-update-docs)
  - [Table of Contents](#table-of-contents)
  - [1. Command Objective](#1-command-objective)
  - [2. Workflow](#2-workflow)

---

## 1. Command Objective

Keep documentation in sync with codebase changes after implementing features, refactoring, or updating configurations.

---

## 2. Workflow

1. Identify modified code files or features.
2. Search `docs/` for relevant architecture, guide, or API documentation.
3. Update metadata header dates and version numbers in modified `.md` files.
4. Run `graphify update .` to ensure the knowledge graph reflects doc updates.
