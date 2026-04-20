<!-- markdownlint-disable MD041 -->

> **Last updated:** 20th April 2026  
> **Version:** 1.0  
> **Authors:** Nicolas TORO  
> **Original language:** English
> **Status:** Done  
> {.is-success}

---

# GitHub Issue Standards Guide

This document defines the official standards for creating, writing, updating, and closing GitHub issues in the Ascension repository.

---

## Table of Contents

- [GitHub Issue Standards Guide](#github-issue-standards-guide)
  - [Table of Contents](#table-of-contents)
  - [1. Purpose](#1-purpose)
  - [2. Language and Tone](#2-language-and-tone)
  - [3. Title Convention](#3-title-convention)
  - [4. Labels and Classification](#4-labels-and-classification)
  - [5. Required Issue Template](#5-required-issue-template)
  - [6. Definition of Done Rules](#6-definition-of-done-rules)
  - [7. Lifecycle Rules](#7-lifecycle-rules)
  - [8. Anti-patterns to Avoid](#8-anti-patterns-to-avoid)
  - [9. Quality Checklist Before Creation](#9-quality-checklist-before-creation)
  - [10. Quick Issue Snippet](#10-quick-issue-snippet)

---

## 1. Purpose

The goal of this policy is to keep the backlog consistent, actionable, and maintainable.

Every issue must:
- describe a clear problem or objective;
- include measurable completion criteria;
- remain synchronized with the real implementation state.

---

## 2. Language and Tone

- All issue content must be written in English.
- Titles and descriptions must be concise, specific, and technical.
- Avoid vague wording such as "done", "works", or "improve" without measurable criteria.

---

## 3. Title Convention

Use the following format:

`<DOMAIN>: <short action-oriented summary>`

Recommended domains:
- `AI`
- `SERVER`
- `MOBILE`
- `SETUP`
- `CI/CD`
- `AUTH`
- `SECURITY`
- `OBSERVABILITY`
- `CONTRACT`
- `PROFESSIONAL`
- `RNCP`

Examples:
- `SERVER: enforce auth middleware on protected routes`
- `MOBILE: improve analysis result empty states`
- `CI/CD: add Go backend test job`

---

## 4. Labels and Classification

Each issue must include at least one domain label (`AI`, `Server`, `Mobile`, `CI/CD`, `Documentation`, etc.).

Squad workflow can add optional labels:
- one type label (`type:feature`, `type:bug`, `type:chore`, `type:spike`, `type:epic`);
- one priority label (`priority:p0`, `priority:p1`, `priority:p2`) unless explicitly justified.
- one status label (`go:yes`, `go:no`, `go:needs-research`)

---

## 5. Required Issue Template

Use this structure for all new issues.

```md
Description 

## Definition of Done
- [ ] Objective, testable criterion 1
- [ ] Objective, testable criterion 2
- [ ] Objective, testable criterion 3
```

Opitional sections can be added when relevant:

```md
## Context
Briefly explain why this issue exists and what problem it solves.

## Goal
Describe the expected end state in one paragraph.

## Scope
- In scope item 1
- In scope item 2

## Out of Scope
- Explicitly excluded item 1
- Explicitly excluded item 2

## Dependencies
- Related issue/PR/doc links

## Endpoints
Describe any API endpoints added/modified by this issue, with request/response examples.

## Validation
- [ ] Tests added/updated
- [ ] Documentation updated if behavior changed
```

---

## 6. Definition of Done Rules

A valid Definition of Done must be:
- observable in code, CI, runtime behavior, or documentation;
- unambiguous and testable;
- complete for both happy path and key failure scenarios.

Do not:
- check boxes without verifiable evidence;
- keep outdated criteria after architecture changes;
- mark an issue as done if critical security requirements are not met.

---

## 7. Lifecycle Rules

1. Creation:
- create issues with complete structure and labels.

2. Triage:
- validate duplicate risk;
- validate roadmap alignment;
- add dependencies and links.

3. Execution:
- update issue text when scope or implementation changes;
- keep endpoints, schemas, and status names up to date.

4. Closure:
- close only when all DoD items are verified;
- add a final comment with PR/commit references;
- if no longer relevant, close with explicit reason (`obsolete`, `duplicate`, `superseded`).

---

## 8. Anti-patterns to Avoid

1. Open issue with 100% completed DoD checkboxes.
2. Issue body containing outdated endpoints or payloads.
3. Truncated Markdown blocks (for example, unclosed code fences).
4. Multiple issues with the same implementation scope.
5. Security claims marked as done while implementation does not satisfy them.

---

## 9. Quality Checklist Before Creation

Before creating an issue, verify:
- [ ] Title follows `<DOMAIN>: ...`
- [ ] Labels are present
- [ ] Mandatory sections are present
- [ ] DoD is measurable and testable
- [ ] Endpoints and schemas are accurate
- [ ] No overlapping duplicate exists

---

## 10. Quick Issue Snippet

```md
...

## Definition of Done
- [ ] ...
- [ ] ...
- [ ] ...
```
