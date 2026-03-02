> **Last updated:** 10th February 2026  
> **Version:** 1.0  
> **Authors:** Nicolas  
> **Status:** Done  
> {.is-success}

---

# Markdown Style Guide & Conventions

This document defines the formatting standards for all Markdown files in this project. Adhering to these rules ensures consistency, readability, and a professional look across the documentation.

---

## Table of Contents

- [Markdown Style Guide \& Conventions](#markdown-style-guide--conventions)
  - [Table of Contents](#table-of-contents)
  - [1. General Principles](#1-general-principles)
  - [2. File Naming Convention](#2-file-naming-convention)
  - [3. Required Header](#3-required-header)
  - [4. Structural Rules](#4-structural-rules)
    - [4.1 Headings and Separation](#41-headings-and-separation)
    - [4.2 Lists and Spacing](#42-lists-and-spacing)
    - [4.3 Table of Contents](#43-table-of-contents)
  - [5. Tooling \& Automation](#5-tooling--automation)

---

## 1. General Principles

- **Language:** All content must be written in **English**. Rare exceptions may be granted for specific technical terms or local names that lack a direct translation.
- **Standardization:** All files must follow the **CommonMark** or **GitHub Flavored Markdown (GFM)** specifications.
- **Formatting Tool:** To avoid manual formatting errors, **Prettier** must be used to clean and format every file before any commit.

---

## 2. File Naming Convention

All Markdown filenames must follow the **kebab-case** convention:

- Use only lowercase letters.
- Use hyphens (`-`) to separate words.
- **Example:** `technical-documentation-v1.md` (Correct) vs `Technical_Doc.md` (Incorrect).

---

## 3. Required Header

Every single Markdown file must start with the following header block using blockquotes:

```markdown
> **Last updated:** [Day] [Month] [Year]  
> **Version:** [X.X]  
> **Authors:** [Name]
> **Status:** [Status]
{.is-[status-color]}  
```

---

## 4. Structural Rules

### 4.1 Headings and Separation

- A **Horizontal Rule** (`---`) must be placed before every major heading (`##`).
- Always include a single space after the `#` symbols (e.g., `## Title`).
- Never skip heading levels (don't go from `#` to `###`).

### 4.2 Lists and Spacing

- Use the hyphen `-` for unordered lists.
- Leave one empty line between paragraphs and before/after code blocks.

### 4.3 Table of Contents

Every Markdown file that contains headings must include a Table of Contents (TOC) at the beginning of the file, after the header. The TOC should list all major sections and subsections to facilitate navigation.

---

## 5. Tooling & Automation

To maintain these standards, it is highly recommended to use the following setup:

1.  **Prettier:** Install the Prettier extension in your IDE or run `npx prettier --write .`
2.  **Format on Save:** Enable "Format on Save" in your editor settings to ensure the style guide is applied automatically.

---
