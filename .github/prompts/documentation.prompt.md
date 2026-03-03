---
name: documentation
description: Create or update a Markdown documentation file following the project's style guide
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

## When updating an existing file

- Keep the original author(s) in the `Authors` field; add your own name only if you made substantial changes.
- Update `Last updated` to today's date in the format `3rd March 2026`.
- Bump the patch version (e.g. `1.0` → `1.1`) for content changes, minor version for structural rewrites.
