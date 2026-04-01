<!-- markdownlint-disable MD041 -->

> **Last updated:** 2nd April 2026  
> **Version:** 1.0  
> **Authors:** Nicolas  
> **Status:** Done  
> {.is-success}

---

# Documentation Accessibility Compliance Statement

This document explains how Ascension documentation is structured to meet accessibility expectations and remain usable when automatically published to both **GitHub Wiki** and **Wiki.js**.

---

## Table of Contents

- [Documentation Accessibility Compliance Statement](#documentation-accessibility-compliance-statement)
  - [Table of Contents](#table-of-contents)
  - [Scope](#scope)
  - [Publication Context](#publication-context)
  - [Reference Standards](#reference-standards)
  - [Applied Accessibility Rules](#applied-accessibility-rules)
  - [How Compliance Is Demonstrated](#how-compliance-is-demonstrated)
  - [Evidence and Governance](#evidence-and-governance)
  - [Conclusion](#conclusion)

---

## Scope

This statement applies to Markdown documentation located under `docs/` and published through the project documentation workflow.

It covers:

- source Markdown authoring rules,
- renderer compatibility for GitHub Wiki and Wiki.js,
- accessibility controls expected during authoring and review.

---

## Publication Context

Documentation is authored once and then distributed to two targets:

- **GitHub Wiki** (generated pages from `docs/`),
- **Wiki.js** (native Markdown rendering).

Because both targets parse Markdown differently in edge cases, accessibility requirements are defined using renderer-safe patterns (headings, lists, links, alt text, and plain-language structure) that remain accessible in both environments.

---

## Reference Standards

The documentation process is aligned with the following references:

- **WCAG 2.1 Level AA** principles (Perceivable, Operable, Understandable, Robust),
- **CommonMark / GFM** syntax constraints for consistent parsing,
- project-level Markdown conventions in `docs/00-start-here/guidelines/markdown-guidelines.md`.

This is a documentation conformance statement for Markdown content quality; it does not replace a full external legal accessibility audit of every downstream rendered page.

---

## Applied Accessibility Rules

The project guideline enforces accessibility-oriented authoring rules, including:

- hierarchical headings with no skipped levels,
- mandatory Table of Contents for navigability,
- descriptive links (no ambiguous "click here" phrasing),
- meaningful alternative text for informative images,
- no color-only meaning without text equivalent,
- explicit header rows in tables,
- fenced code blocks with language identifiers,
- concise and clear wording,
- text summaries accompanying Mermaid diagrams.

These rules are selected specifically because they survive the automated publication flow and remain understandable with assistive technologies.

---

## How Compliance Is Demonstrated

Compliance is demonstrated through a **rules + process** model:

1. Authors follow the Markdown guideline before committing documentation changes.
2. Reviews check accessibility criteria as part of documentation quality.
3. Rendered output is validated on both GitHub Wiki and Wiki.js for readability and structure preservation.

In practice, this proves that accessibility is embedded in the authoring lifecycle rather than added at the end.

---

## Evidence and Governance

Primary evidence artifacts:

- `docs/00-start-here/guidelines/markdown-guidelines.md` (normative writing rules),
- `docs/index.md` (publication process and wiki synchronization references),
- this compliance statement as an explicit accessibility rationale.

Governance principles:

- accessibility is a release quality criterion for documentation updates,
- accessibility regressions in documentation must be corrected before final validation,
- new documentation templates must preserve these accessibility constraints.

---

## Conclusion

Ascension documentation is maintained with explicit accessibility rules, a shared review process, and publication-aware Markdown conventions.

As a result, the documentation corpus is structured to respect accessibility best practices across both GitHub Wiki and Wiki.js publication targets.
