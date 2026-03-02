> **Last updated:** 26th February 2026  
> **Version:** 1.1  
> **Authors:** Nicolas  
> **Status:** Done  
> {.is-success}

---

# Git Branch Standards Guide

This document defines the standards to follow when creating, using, and merging branches in our project.  
Good branch conventions improve collaboration, prevent conflicts, and ensure a clean Git history.

---

## Table of Contents

- [Git Branch Standards Guide](#git-branch-standards-guide)
  - [Table of Contents](#table-of-contents)
  - [1. Branch naming conventions](#1-branch-naming-conventions)
    - [1.1 Allowed examples](#11-allowed-examples)
    - [1.2 Disallowed examples](#12-disallowed-examples)
  - [2. Branch usage rules](#2-branch-usage-rules)
  - [3. Pull request process](#3-pull-request-process)
  - [4. Enabling local checks](#4-enabling-local-checks)
  - [5. Summary](#5-summary)

---

## 1. Branch naming conventions

- **Language**: English only
- **Format**: kebab-case for the descriptive part (lowercase letters and numbers, words separated by single hyphens)
- **Overall format**: /
  - `type` must be one of the keywords listed in `.github/keywords.txt` (for example: `feat`, `fix`, `docs`, `chore`, ...)
  - `description` must be kebab-case and must not be empty
- **Special branches**: `main` and `dev` exist but are protected, do not push or commit directly to them.

Important: branch names are validated by the script `.github/scripts/check_branch`.  
If the name does not match the required format, CI (GitHub Actions) will fail and/or local hooks can block the push.

### 1.1 Allowed examples

✅ `feat/add-login-flow`  
✅ `fix/login-typo`  
✅ `docs/api-spec`  
✅ `chore/update-dependencies`

### 1.2 Disallowed examples

❌ `userAuth` (not kebab-case and missing type)  
❌ `feature-for-user-authentication` (missing type prefix)  
❌ `fix the issue with login` (full sentence / spaces)  
❌ `feat/InvalidCase` (contains uppercase)

---

## 2. Branch usage rules

- No direct commits or pushes on `main` or `dev`.
  - These branches are protected by policy: direct commits should not be made.
  - If someone pushes directly, GitHub Actions in this repository are configured to detect and fail or (depending on the workflow) automatically revert the push. In any case, a push to `main`/`dev` that doesn't follow the workflow will be rejected by automation or must be fixed by a maintainer.
- Every work must be done on a feature/fix branch following the `<type>/<description>` kebab-case rule.
- The canonical flow is:
  1.  Create a branch from `dev` (or from the appropriate base branch): `git checkout -b feat/my-feature`
  2.  Work and commit on that branch
  3.  Open a Pull Request targeting `dev`
- Enforcement:
  - A server-side prevention is not available without changing repository settings; therefore we enforce rules using:
    - `.github/scripts/check_branch` ran by GitHub Actions (CI will fail the push/PR if the branch name is invalid)
    - Optional client hook (contributors should enable `.github/hooks/pre-push`) to block accidental pushes locally
    - GitHub Actions workflows that will reject or revert direct pushes to `main` if they happen
- Where to check the allowed `type` keywords: `.github/keywords.txt`.
  - Keep that file up to date; the `check_branch` script reads it to validate the `type` portion.

---

## 3. Pull request process

When opening a pull request (PR), follow these rules:

1.  Title Must follow the format:merge: "" into ""Example: `merge: "feat/add-login-flow" into "dev"`
2.  Description Provide either:
    - The list of commits from the branch, OR
    - A detailed summary of the changes introduced. A template is available in `.github/pull_request_template.md`.
3.  Metadata
    - Add the correct labels
    - Specify the milestone impacted
    - Link the PR to the relevant GitHub Project with every field filled in
    - If related issues exist, link them
4.  Assignees & Reviews
    - Assign yourself to the PR
    - The PR must receive at least one peer review before merging in preference Nicolas TORO
5.  After merging
    - The branch must be deleted
    - The merge commit must use the same title and description as the PR

---

## 4. Enabling local checks

To help contributors avoid CI failures, local Git hooks are provided in `.github/hooks/`.
Activate them on your machine with:

```sh
git config core.hooksPath .github/hooks
```

This command only needs to be run once per clone. The following hooks will then be active:

- `pre-commit` — auto-formats staged code before committing.
- `commit-msg` — validates the commit message format.
- `pre-push` — validates the branch name and blocks direct pushes to `main`.

For a detailed description of each hook and script, refer to the [GitHub Actions & Hooks Guide](./github-actions-and-hooks-guide.md).

---

## 5. Summary

- Branch names = `<type>/<description>` where `type` is from `.github/keywords.txt` and `description` is kebab-case (lowercase, numbers, hyphens only).
- No direct commits/pushes to `main` or `dev` — CI will fail or automation will revert; local hooks are recommended to prevent accidental pushes.
- Use PRs, follow the title/description/metadata rules, get reviews, and delete branches after merging.
