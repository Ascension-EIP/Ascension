---
name: documentation
description: Create or update all Markdown documentation files following the project's style guide
---

## ⚠️ Mandatory first step

Before writing, editing, or improving **any** Markdown documentation, you MUST read the full project style guide:

```
docs/guidelines/markdown-guidelines.md
```

Do not skip this step, even if you think you already know the rules. The guidelines are the source of truth — if there is a conflict between your defaults and the guide, the guide wins.

---

## Checklist — apply to every file you create or modify

After reading the guidelines, verify every point below before outputting a file:

- [ ] **Header block** — the file starts with the required blockquote header:
  ```
  > **Last updated:** [Day] [Month] [Year]  
  > **Version:** [X.X]  
  > **Authors:** [Name]  
  > **Status:** [Status]  
  > {.is-[status-color]}
  ```
  Each line ends with **two trailing spaces** to produce a Markdown line break.

- [ ] **Horizontal rule after header** — a `---` separator immediately follows the header block.

- [ ] **Top-level heading** — a single `# Title` heading comes right after the separator.

- [ ] **Table of Contents** — every file with headings must include a TOC after the title, listing all `##` and `###` sections.

- [ ] **Horizontal rule before every `##` heading** — a `---` separator is placed before each major section.

- [ ] **Heading levels are not skipped** — no jumping from `##` to `####`.

- [ ] **Unordered lists use `-`**, not `*` or `+`.

- [ ] **Empty line** before and after every code block and between paragraphs.

- [ ] **Filename is kebab-case** — all lowercase, words separated by hyphens.

- [ ] **Language is English** — unless a specific exception is documented.

---

## Files to ignore

Before auditing or mass-updating documentation, check for a `.docignore` file at the root of any directory you are working in. Files and patterns listed there **must not** be modified.

The following files and patterns are **always ignored** — never add a project header, TOC, or apply these guidelines to them:

- `.github/prompts/*.prompt.md` — Copilot prompt files use their own YAML frontmatter format and must not be reformatted.
- `.github/agents/*.agent.md` — Squad agent definition files.
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

- Keep the original author(s) in the `Authors` field; add your own name only if you made substantial changes.
- Update `Last updated` to today's date in the format `4th March 2026`.
- Bump the patch version (e.g. `1.0` → `1.1`) for content changes, minor version for structural rewrites.
