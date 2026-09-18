---
id: 9350e125-1246-4b4e-8b76-7abb7181b11e
---

:::success
**Version:** 1.1
**Original language:** English
:::

---

# AI Command: Update Documentation (`/update-docs`)

This document serves as an execution protocol for inspecting modified features, architecture, or APIs and updating all relevant documentation files accordingly.

---

## Table of Contents

- [AI Command: Update Documentation (](#ai-command-update-documentation-update-docs)`/update-docs`[)](#ai-command-update-documentation-update-docs)
  - [Table of Contents](#table-of-contents)
  - [1\. Command Objective](#1-command-objective)
  - [2\. Workflow](#2-workflow)

---

## 1\. Command Objective

Keep documentation in sync with codebase changes after implementing features, refactoring, or updating configurations.

---

## 2\. Workflow

1. Identify modified code files or features.
2. Search `docs/` for relevant architecture, guide, or API documentation.
3. Update metadata header version numbers and status container in modified `.md` files.
4. Run `graphify update .` to ensure the knowledge graph reflects doc updates.