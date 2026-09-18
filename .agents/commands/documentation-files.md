---
name: documentation-files
description: "AI Command: Markdown Documentation Files (/documentation-files)"
globs: ["*.md"]
alwaysApply: false
---

:::success
**Version:** 1.1
**Original language:** English
:::

---

# AI Command: Documentation Files (`/documentation-files`)

This document serves as an execution protocol for creating and maintaining Markdown documentation files across the project.

---

## Table of Contents

- [AI Command: Documentation Files (](#ai-command-documentation-files-documentation-files)`/documentation-files`[)](#ai-command-documentation-files-documentation-files)
  - [Table of Contents](#table-of-contents)
  - [1\. Command Objective](#1-command-objective)
  - [2\. Guideline Enforcement](#2-guideline-enforcement)
  - [3\. Mandatory Structure](#3-mandatory-structure)

---

## 1\. Command Objective

Ensure all Markdown files created or updated adhere strictly to the repository markdown guidelines (`docs/developer/guidelines/markdown-guidelines.md`).

---

## 2\. Guideline Enforcement

Before writing or editing any `.md` file, consult:

```
docs/developer/guidelines/markdown-guidelines.md
```

---

## 3\. Mandatory Structure

- **Header Block**: Every Markdown file must start with a Densho metadata status container (`:::success`, `:::warning`, `:::danger`).
- **Title & TOC**: Single `# Title` heading followed by a Table of Contents.
- **Section Separators**: Horizontal rules (`---`) before every `##` heading.
- **Kebab-Case Naming**: All markdown filenames must be lowercase kebab-case.
