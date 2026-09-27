---
name: documentation-files
description: "Create or update all Markdown documentation files following the project's style guide (/documentation-files)"
globs: ["*.md"]
alwaysApply: false
---

## ⚠️ Mandatory first step

Before writing, editing, or improving **any** Markdown documentation, you MUST read the full project style guide:

```
docs/developer/guidelines/markdown-guidelines.md
```

Do not skip this step, even if you think you already know the rules. The guidelines are the source of truth — if there is a conflict between your defaults and the guide, the guide wins.

---

## Checklist — apply to every file you create or modify

After reading the guidelines, verify every point below before outputting a file:

- [ ] **Densho frontmatter header** — do **not** add, touch, or modify the YAML frontmatter header (`--- id: ... ---`); it is managed automatically by Densho.
- [ ] **Header block** — the file starts with the required Densho status container callout:

  ```markdown
  :::status
  **Version:** [X.X]
  :::
  ```

  Each line ends with **two trailing spaces** to produce a Markdown line break.
  Authorized container statuses:
  - `:::success` for completed (`Done`) documents, and frozen (`Final`) documents with `DON'T EDIT THIS FILE !` added after the version.
  - `:::warning` for `In progress` or `Need update` documents.
  - `:::danger` for `Todo` (planned) documents.
- [ ] **Horizontal rule after header** — a `---` separator immediately follows the header block.
- [ ] **Top-level heading** — a single `# Title` heading comes right after the separator.
- [ ] **Horizontal rule before every** `##` **heading** — a `---` separator is placed before each major section.
- [ ] **Heading levels are not skipped** — no jumping from `##` to `####`.
- [ ] **Unordered lists use** `-`, not `*` or `+`.
- [ ] **Empty line** before and after every code block and between paragraphs.
- [ ] **Diagrams use Mermaid** — always use ` ```mermaid ` for all diagrams, charts, and schemas; never use text / ASCII art (` ```text `).
- [ ] **Filename is kebab-case** — all lowercase, words separated by hyphens.
- [ ] **Language is English or French**.

---

## Files to ignore

Before auditing or mass-updating documentation, check for a `.docignore` file at the root of any directory you are working in. Files and patterns listed there **must not** be modified.

The following files and patterns are **always ignored** — never add a project header or apply these guidelines to them:

- `.github/prompts/*.prompt.md` — Copilot prompt files use their own YAML frontmatter format and must not be reformatted.
- `.github/agents/*.agent.md` — Copilot agent definition files.
- `**/.docignore` — the ignore files themselves.
- Any file explicitly listed inside a `.docignore` file found in the same directory or any parent directory.

### How `.docignore` works

Create a `.docignore` file in any directory (or at the repo root) to exclude specific files from documentation enforcement. Syntax mirrors `.gitignore`:

```
# Ignore a specific file
some-file.md

# Ignore all files in a folder
some-folder/

# Ignore by pattern
*.generated.md
```

---

## When updating an existing file

- Bump the patch version (e.g. `1.0` → `1.1`) for content changes, minor version for structural rewrites.
- Adjust the status container type if the document lifecycle status changes (e.g. `:::warning` → `:::success`).
