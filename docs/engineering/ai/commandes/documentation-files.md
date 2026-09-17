---
name: documentation-files
description: "AI Command: Markdown Documentation Files (/documentation-files)"
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

# AI Command: Documentation Files (`/documentation-files`)

This document serves as an execution protocol for creating and maintaining Markdown documentation files across the project.

---

## Table of Contents

- [AI Command: Documentation Files (`/documentation-files`)](#ai-command-documentation-files-documentation-files)
  - [Table of Contents](#table-of-contents)
  - [1. Command Objective](#1-command-objective)
  - [2. Guideline Enforcement](#2-guideline-enforcement)
  - [3. Mandatory Structure](#3-mandatory-structure)

---

## 1. Command Objective

Ensure all Markdown files created or updated adhere strictly to the repository markdown guidelines (`docs/00-start-here/guidelines/markdown-guidelines.md`).

---

## 2. Guideline Enforcement

Before writing or editing any `.md` file, consult:
```
docs/00-start-here/guidelines/markdown-guidelines.md
```

---

## 3. Mandatory Structure

- **Header Block**: Every Markdown file must start with a metadata blockquote.
- **Title & TOC**: Single `# Title` heading followed by a Table of Contents.
- **Section Separators**: Horizontal rules (`---`) before every `##` heading.
- **Kebab-Case Naming**: All markdown filenames must be lowercase kebab-case.
