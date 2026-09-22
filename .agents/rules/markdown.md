
# Markdown Style Guide & Conventions

This document defines the formatting standards for all Markdown files in this project. Adhering to these rules ensures consistency, readability, and a professional look across the documentation.


---

## 1\. General Principles

- **Language:** All content must be written **in English or in French**. Rare exceptions may be granted for specific technical terms or local names that lack a direct translation.
- **Standardization:** All files must follow the **CommonMark** or **GitHub Flavored Markdown (GFM)** specifications.
- **Formatting Tool:** To avoid manual formatting errors, **Prettier** must be used to clean and format every file before any commit.

---

## 2\. File Naming Convention

All Markdown filenames must follow the **kebab-case** convention:

- Use only lowercase letters.
- Use hyphens (`-`) to separate words.
- **Example:** `technical-documentation-v1.md` (Correct) vs `Technical_Doc.md` (Incorrect).

---

## 3\. Headers & Status Block

### 3.1 Densho Metadata Header (Frontmatter) — Do Not Add or Modify

The YAML frontmatter header containing file metadata (such as the document `id`) is managed completely and automatically by **Densho**:

```yaml
---
id: 49dc5f35-6ba9-4ac3-8532-92c9652da56a
---
```

:::danger
**Strict Frontmatter Rules:**
- **Never add it manually:** When creating a new Markdown file, do **not** write, copy, or add a YAML frontmatter header (`--- id: ... ---`). Densho generates and attaches it automatically.
- **Never modify or remove it:** When editing an existing file, do **not** touch, edit, or delete this header. Leave it strictly as is.
:::

### 3.2 Required Status Callout

Immediately after the Densho frontmatter (or at the very top of a newly created file before Densho processing), every single Markdown file must start with the following header block using Densho status container callouts:

```markdown
:::status
**Version:** [X.X]
:::
```

#### Status Types

The container status must strictly use one of the authorized container types:

| Status Container | Previous Status Equivalent | Description | Notes |
| --- | --- | --- | --- |
| `:::success` | `Done`, `Final` | Completed and validated document. | If the document is frozen/final, append `DON'T EDIT THIS FILE !` on a new line after the version. |
| `:::warning` | `In progress`, `Need update` | Work in progress or outdated document needing update. | |
| `:::danger` | `Todo` | Planned document not yet written. | |

#### Examples

**Completed document:**

```markdown
:::success
**Version:** 1.0
:::
```

**Final / Frozen document:**

```markdown
:::success
**Version:** 1.0
DON'T EDIT THIS FILE !
:::
```

**Work in progress or needing update:**

```markdown
:::warning
**Version:** 0.2
:::
```

**To-do / stub document:**

```markdown
:::danger
**Version:** 0.1
:::
```

---

## 4\. Structural Rules

### 4.1 Headings and Separation

- A **Horizontal Rule** (`---`) must be placed before every major heading (`##`).
- Always include a single space after the `#` symbols (e.g., `## Title`).
- Never skip heading levels (don't go from `#` to `###`).

### 4.2 Lists and Spacing

- Use the hyphen `-` for unordered lists.
- Use `1.` for ordered lists. Do not use `1)` style markers.
- Leave one empty line between paragraphs and before/after code blocks.

### 4.3 Accessibility Rules

All documentation must remain accessible on both **GitHub Wiki** and **Densho** renderers.

- Keep a strict heading hierarchy (`#` → `##` → `###`) so screen readers expose a logical outline.
- Use descriptive link labels (avoid "click here"), so link purpose is understandable out of context.
- Provide meaningful alt text for informative images: `![Description of the visual](./path/image.png)`.
- Do not rely on color alone to convey meaning; add text labels such as **Success**, **Warning**, **Error**.
- Use readable table structures with explicit header rows and avoid complex merged-cell layouts.
- Add language identifiers to fenced code blocks (e.g., ` ```ts `, ` ```bash `) for better assistive parsing.
- Keep sentence structure simple and concise, and expand uncommon acronyms on first occurrence.
- For Mermaid diagrams, include a short text summary immediately before or after the diagram.

### 4.4 Diagrams and Visual Representations

- **No Text / ASCII Graphs:** Never use plain text / ASCII art code blocks (` ```text `) to draw graphs, schemas, flowcharts, or architecture diagrams.
- **Use Mermaid:** Always use **Mermaid** blocks (` ```mermaid `) instead for all diagrams, flowcharts, architecture overviews, timelines, and sequence charts.
- **Accessibility:** Always include a concise text description or summary immediately before or after the Mermaid diagram to ensure full accessibility.

---

## 5\. Tooling & Automation

To maintain these standards, it is highly recommended to use the following setup:

1. **Prettier:** Install the Prettier extension in your IDE or run `npx prettier --write .`
2. **Format on Save:** Enable "Format on Save" in your editor settings to ensure the style guide is applied automatically.

---
