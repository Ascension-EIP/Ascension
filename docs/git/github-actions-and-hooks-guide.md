> **Last updated:** 26th February 2026  
> **Version:** 1.0  
> **Authors:** Nicolas TORO  
> **Status:** Done  
> {.is-success}

---

# GitHub Actions & Hooks Guide

This document describes all the Git hooks, validation scripts, and GitHub Actions workflows used in the Ascension project.
These mechanisms enforce code quality, naming conventions, and automate the CI/CD pipeline.

---

## Table of Contents

- [GitHub Actions \& Hooks Guide](#github-actions--hooks-guide)
  - [Table of Contents](#table-of-contents)
  - [1. Overview](#1-overview)
  - [2. Keywords configuration](#2-keywords-configuration)
  - [3. Git hooks](#3-git-hooks)
    - [3.1 `pre-commit`](#31-pre-commit)
    - [3.2 `commit-msg`](#32-commit-msg)
    - [3.3 `pre-push`](#33-pre-push)
    - [3.4 Enabling hooks locally](#34-enabling-hooks-locally)
  - [4. Validation scripts](#4-validation-scripts)
    - [4.1 `check_branch`](#41-check_branch)
    - [4.2 `check_commit`](#42-check_commit)
    - [4.3 `check_push`](#43-check_push)
    - [4.4 `reformat_code`](#44-reformat_code)
    - [4.5 `get_commits_list`](#45-get_commits_list)
  - [5. GitHub Actions workflows](#5-github-actions-workflows)
    - [5.1 CI workflow (`ci.yml`)](#51-ci-workflow-ciyml)
      - [Job: `check_commit_and_branch`](#job-check_commit_and_branch)
      - [Job: `check_server` (needs: `check_commit_and_branch`)](#job-check_server-needs-check_commit_and_branch)
      - [Job: `check_mobile` (needs: `check_commit_and_branch`)](#job-check_mobile-needs-check_commit_and_branch)
      - [Job: `check_ai` (needs: `check_commit_and_branch`)](#job-check_ai-needs-check_commit_and_branch)
    - [5.2 Deploy workflow (`deploy.yml`)](#52-deploy-workflow-deployyml)
      - [Job: `build_and_push_server`](#job-build_and_push_server)
      - [Job: `build_and_push_mobile`](#job-build_and_push_mobile)
      - [Job: `create_release` (needs: `build_and_push_server`, `build_and_push_mobile`)](#job-create_release-needs-build_and_push_server-build_and_push_mobile)
    - [5.3 Dev-to-production workflow (`dev-to-production.yml`)](#53-dev-to-production-workflow-dev-to-productionyml)
      - [Job: `merge_branch`](#job-merge_branch)
      - [Job: `create_tag` (needs: `merge_branch`)](#job-create_tag-needs-merge_branch)
      - [Job: `mirror_repository` (needs: `merge_branch`)](#job-mirror_repository-needs-merge_branch)
  - [6. Secrets and variables](#6-secrets-and-variables)

---

## 1. Overview

The Ascension project uses a two-layered enforcement strategy:

- **Local enforcement** via Git hooks (in `.github/hooks/`) that run on the contributor's machine before a commit or push is sent to the remote.
- **Remote enforcement** via GitHub Actions workflows (in `.github/workflows/`) that run on every push or pull request in the CI environment.

Both layers rely on the same shared Python validation scripts located in `.github/scripts/`.

```
.github/
├── hooks/
│   ├── pre-commit            # Runs before a commit is created
│   ├── commit-msg            # Validates the commit message format
│   └── pre-push              # Validates the branch and checks before a push
├── scripts/
│   ├── check_branch          # Validates the branch name format
│   ├── check_commit          # Validates the commit message format
│   ├── check_push            # Runs additional checks before a push
│   ├── get_commits_list      # Lists commits between dev and the current branch
│   └── reformat_code         # Formats all project code using moon
├── workflows/
│   ├── ci.yml                # Continuous Integration on every push / PR
│   ├── deploy.yml            # Build and publish artifacts on version tags
│   └── dev-to-production.yml # Merge dev → main, tag, mirror
└── keywords.txt              # Allowed types for branch names and commit messages
```

---

## 2. Keywords configuration

**File:** `.github/keywords.txt`

This file contains the list of allowed type keywords used to validate both branch names and commit messages.
Each non-empty, non-comment line is treated as a valid keyword.

Current keywords:

| Keyword    | Description                                    |
| ---------- | ---------------------------------------------- |
| `feat`     | New feature                                    |
| `fix`      | Bug fix                                        |
| `docs`     | Documentation changes                          |
| `style`    | Code style / formatting, no logic change       |
| `refactor` | Code refactoring                               |
| `test`     | Adding or updating tests                       |
| `build`    | Build system or dependency changes             |
| `perf`     | Performance improvements                       |
| `ci`       | Continuous Integration configuration changes   |
| `chore`    | Maintenance tasks                              |
| `revert`   | Reverting a previous commit                    |
| `add`      | Adding new files                               |
| `remove`   | Removing files or dead code                    |
| `rename`   | Renaming files or classes                      |
| `move`     | Moving files                                   |
| `merge`    | Merging branches                               |
| `init`     | Initializing components or project structure   |
| `details`  | Detailed multi-line commits                    |

> ⚠️ Both the `check_branch` and `check_commit` scripts read this file at runtime.
> Keeping it up to date is critical — adding a new type here is enough to unlock it everywhere.

---

## 3. Git hooks

Git hooks are shell scripts stored in `.github/hooks/`. They are **not** active by default; contributors must enable them manually (see [section 3.4](#34-enabling-hooks-locally)).

### 3.1 `pre-commit`

**Triggered:** Before a commit is recorded.

**Behaviour:**

1. If the `docs` submodule has unstaged changes, it is automatically staged.
2. All currently staged files are formatted via `.github/scripts/reformat_code`.
3. The formatted files are re-staged so the commit includes the clean version.

```bash
# Simplified flow
git diff --quiet HEAD -- docs || git add docs
.github/scripts/reformat_code
echo "$FILES" | xargs git add
```

### 3.2 `commit-msg`

**Triggered:** After the developer writes a commit message, before the commit is stored.

**Behaviour:**

- Reads the commit message from the temporary file provided by Git (`$1`).
- Passes it to `.github/scripts/check_commit` for format validation.
- If the message is invalid, the commit is aborted and an error is printed.

### 3.3 `pre-push`

**Triggered:** Before commits are sent to the remote.

**Behaviour on `main` branch:**

- Allows the push only if it is a merge commit whose parent is from the `dev` branch.
- Any other direct push to `main` is rejected with an error message.

**Behaviour on other branches:**

1. Validates the branch name via `.github/scripts/check_branch`.
2. Runs additional checks via `.github/scripts/check_push`.
3. If all checks pass, runs `git pull` before pushing to reduce conflicts.

```
pre-push
├── branch == main?
│   ├── parent in dev? → ✔ allow
│   └── else          → ❌ reject
└── branch != main
    ├── check_branch  → ❌ reject on invalid name
    ├── check_push    → ❌ reject on failed checks
    └── git pull + push
```

### 3.4 Enabling hooks locally

The hooks are stored in `.github/hooks/` instead of `.git/hooks/` so they are tracked by version control.
To activate them on your local machine, run:

```sh
git config core.hooksPath .github/hooks
```

> ℹ️ This command only needs to be run once per clone. After that, all hooks are applied automatically.

---

## 4. Validation scripts

All scripts are stored in `.github/scripts/` and are executable Python or Bash scripts.
They can be invoked both locally (by hooks) and remotely (by GitHub Actions).

### 4.1 `check_branch`

**Language:** Python 3  
**Usage:** `.github/scripts/check_branch <branch_name>`

Validates that a branch name follows the project conventions:

- Branches named `main` or `dev` are always accepted.
- All other branches must follow the format `<type>/<description>` where:
  - `type` is one of the keywords in `.github/keywords.txt`.
  - `description` is non-empty and in **kebab-case** (lowercase letters, digits, and single hyphens).

The script is GitHub Actions-aware: when run inside a workflow (`GITHUB_ACTIONS=true`), it outputs annotations in the GitHub format (`::error title=...::`) so errors appear directly in the workflow summary.

**Exit codes:**

| Code | Meaning                                  |
| ---- | ---------------------------------------- |
| `0`  | Branch is valid                          |
| `1`  | Branch is invalid or configuration error |

### 4.2 `check_commit`

**Language:** Python 3  
**Usage:** `.github/scripts/check_commit "<commit_message>"`

Validates that a commit message follows the Conventional Commits format:

```
<type>(<scope>): <description>
```

- `type` must be one of the keywords in `.github/keywords.txt`.
- `scope` is optional.
- `description` must not be empty.
- Merge commits (starting with `Merge`) are automatically accepted without validation.

Like `check_branch`, the script outputs GitHub Actions annotations when run inside a workflow.

**Exit codes:**

| Code | Meaning            |
| ---- | ------------------ |
| `0`  | Commit is valid    |
| `1`  | Commit is invalid or configuration error |

### 4.3 `check_push`

**Language:** Bash  
**Usage:** `.github/scripts/check_push`

A placeholder script intended for additional pre-push validations (e.g., running tests locally before pushing).
Currently always exits with `0` (all checks pass).

> 🔧 This script is intended to be extended with project-specific checks in the future.

### 4.4 `reformat_code`

**Language:** Bash  
**Usage:** `.github/scripts/reformat_code`

Runs the code formatters for each application using the `moon` task runner:

```bash
moon run server:format   # Rust (rustfmt)
moon run mobile:format   # Dart (dart format)
# moon run ai:format     # Python (disabled)
```

This script is called automatically by the `pre-commit` hook and can also be run manually to format the entire codebase.

### 4.5 `get_commits_list`

**Language:** Bash  
**Usage:** `.github/scripts/get_commits_list`

A utility script that prints the list of commits between `origin/dev` and the current branch.
Useful for reviewing what will be included in a pull request.

```
Current branch: feat/my-feature
Commits between dev and feat/my-feature:
- a1b2c3d feat(auth): add login endpoint
- d4e5f6g fix(auth): handle empty token
```

---

## 5. GitHub Actions workflows

All workflows are in `.github/workflows/`. They share the following common configuration:

- `GITHUB_ACTIONS: true` is set as an environment variable so validation scripts output GitHub-formatted annotations.
- **Concurrency** is configured per workflow and branch: a new run cancels any in-progress run for the same branch.

### 5.1 CI workflow (`ci.yml`)

**Name:** `ascension-ci`  
**Triggers:** Every `push` and `pull_request` event.

This workflow enforces code quality across all services. It is composed of four jobs:

#### Job: `check_commit_and_branch`

Runs first, in parallel with nothing (no dependencies).

| Step                        | Description                                                        |
| --------------------------- | ------------------------------------------------------------------ |
| Checkout (full history)     | Fetches all history to allow `git log` inspection                  |
| Launch commit checker       | Runs `check_commit` on the latest commit message                   |
| Launch branch checker       | Runs `check_branch` on the current branch (skipped for tags)       |

For pull requests, the source branch name is read from `GITHUB_HEAD_REF`.

#### Job: `check_server` (needs: `check_commit_and_branch`)

Validates the Rust server application.

| Step             | Description                                               |
| ---------------- | --------------------------------------------------------- |
| Checkout         | Full history + recursive submodules                       |
| Rust toolchain   | Sets up stable Rust with `rustfmt` and `clippy`           |
| Install moon     | Sets up the moon task runner                              |
| Cache Cargo      | Caches `~/.cargo` and `apps/server/target`                |
| Cache moon store | Caches `.moon/cache`                                      |
| Format check     | `moon run server:format` — fails if code is not formatted |
| Lint             | `moon run server:lint` — runs Clippy                      |
| Build            | `moon run server:build-release` — builds in release mode  |
| Test             | `moon run server:test` — runs unit tests                  |

#### Job: `check_mobile` (needs: `check_commit_and_branch`)

Validates the Flutter mobile application.

| Step                   | Description                                               |
| ---------------------- | --------------------------------------------------------- |
| Checkout               | Full history + recursive submodules                       |
| Set up Flutter         | Installs Flutter 3.41.2 (stable channel) with cache       |
| Cache pub dependencies | Caches `~/.pub-cache` and `.dart_tool`                    |
| Install moon           | Sets up the moon task runner                              |
| Cache moon store       | Caches `.moon/cache`                                      |
| Format check           | `moon run mobile:format` — fails if code is not formatted |
| Lint                   | `moon run mobile:lint` — runs `dart analyze`              |
| Test                   | `moon run mobile:test` — runs unit tests                  |

#### Job: `check_ai` (needs: `check_commit_and_branch`)

Validates the Python AI application.

| Step                    | Description                                        |
| ----------------------- | -------------------------------------------------- |
| Checkout                | Full history + recursive submodules                |
| Set up Python           | Installs Python 3.12 with pip cache                |
| Install moon            | Sets up the moon task runner (no cache)            |
| Cache moon store        | Caches `.moon/cache`                               |
| Cache Python venv       | Caches `apps/ai/venv`                              |
| Install dependencies    | `moon run ai:install`                              |
| Lint                    | `moon run ai:lint`                                 |
| Test                    | `moon run ai:test`                                 |

```
push / pull_request
        │
        ▼
check_commit_and_branch
        │
   ┌────┼────┐
   ▼    ▼    ▼
server mobile  ai
```

### 5.2 Deploy workflow (`deploy.yml`)

**Name:** `ascension-deploy`  
**Triggers:** Push of a tag matching the pattern `v*` (e.g., `v0.1.0`).

This workflow builds and publishes production artifacts. It is composed of three jobs:

#### Job: `build_and_push_server`

Builds the Rust server Docker image and pushes it to **GitHub Container Registry (GHCR)**.

| Step                 | Description                                                                   |
| -------------------- | ----------------------------------------------------------------------------- |
| Checkout             | Full history                                                                  |
| Extract tag version  | Extracts the tag from `GITHUB_REF` (e.g., `v0.2.1`)                           |
| Set image prefix     | Computes `ghcr.io/<owner>` (lowercase)                                        |
| Log in to GHCR       | Authenticates with `GITHUB_TOKEN`                                             |
| Set up Docker Buildx | Enables multi-platform builds                                                 |
| Build and push image | Builds `apps/server/Dockerfile` and pushes two tags: `<version>` and `latest` |

#### Job: `build_and_push_mobile`

Builds the Flutter Android APK.

| Step                    | Description                                                          |
| ----------------------- | -------------------------------------------------------------------- |
| Checkout                | Full history                                                         |
| Extract tag version     | Extracts the tag from `GITHUB_REF`                                   |
| Set up Flutter          | Installs Flutter (stable channel) with cache                         |
| Get dependencies        | Runs `flutter pub get` in `apps/mobile`                              |
| Build Android APK       | Runs `flutter build apk --release`                                   |
| Upload Android artifact | Uploads `app-release.apk` as a workflow artifact (30 days retention) |

> ℹ️ The AI Docker image job is currently commented out and not active.

#### Job: `create_release` (needs: `build_and_push_server`, `build_and_push_mobile`)

Creates a GitHub Release with the built artifacts.

| Step                      | Description                                                      |
| ------------------------- | ---------------------------------------------------------------- |
| Checkout                  | Full history                                                     |
| Extract tag version       | Extracts the tag from `GITHUB_REF`                               |
| Download Android artifact | Fetches the APK artifact from the `build_and_push_mobile` job    |
| Create GitHub Release     | Creates a release with auto-generated notes and attaches the APK |

```
push tag v*
        │
   ┌────┴───────────────┐
   ▼                    ▼
build_and_push_server  build_and_push_mobile
   │                    │
   └────────┬───────────┘
            ▼
      create_release
```

### 5.3 Dev-to-production workflow (`dev-to-production.yml`)

**Name:** `ascension-dev-to-production`  
**Triggers:** Manual dispatch (`workflow_dispatch`) only.

This workflow promotes the `dev` branch to production by performing three sequential operations:

#### Job: `merge_branch`

Merges `dev` into `main`.

| Step              | Description                                                                      |
| ----------------- | -------------------------------------------------------------------------------- |
| Generate token    | Uses the `APP_ID` / `APP_PRIVATE_KEY` secrets to create a GitHub App token       |
| Checkout          | Checks out the `dev` branch with full history                                    |
| Merge dev → main  | Uses `everlytic/branch-merge` to merge `dev` into `main` with a formatted commit |

The merge commit message format is: `merge: \`dev\` into \`main\``.

#### Job: `create_tag` (needs: `merge_branch`)

Computes and pushes the next semantic version tag on `main`.

| Step                     | Description                                                         |
| ------------------------ | ------------------------------------------------------------------- |
| Generate token           | Creates a GitHub App token                                          |
| Checkout main            | Checks out `main` with full history                                 |
| Compute next semver      | Reads the latest `v*.*.*` tag and increments the **patch** version  |
| Push new tag             | Creates and pushes the new tag (e.g., `v0.1.0` → `v0.1.1`)         |

The patch increment strategy: if no tag exists yet, the first tag is `v0.1.0`.

#### Job: `mirror_repository` (needs: `merge_branch`)

Mirrors the repository to an external location.

| Step                  | Description                                              |
| --------------------- | -------------------------------------------------------- |
| Checkout main         | Checks out `main` with full history                      |
| Mirror to external    | Uses `pixta-dev/repository-mirroring-action` with the `MIRROR_SSH_KEY` secret |

> ⚠️ This job only runs when the repository is `Ascension-EIP/Ascension`.

```
workflow_dispatch
        │
        ▼
   merge_branch
   (dev → main)
        │
   ┌────┴────┐
   ▼         ▼
create_tag  mirror_repository
(semver)    (external mirror)
        │
        ▼
  (triggers deploy.yml
   via the new tag)
```

---

## 6. Secrets and variables

The following secrets and variables must be configured in the GitHub repository settings for the workflows to function correctly.

| Name                    | Type     | Used in                    | Description                                          |
| ----------------------- | -------- | -------------------------- | ---------------------------------------------------- |
| `GITHUB_TOKEN`          | Secret   | `deploy.yml`               | Built-in GitHub token for GHCR authentication        |
| `APP_ID`                | Secret   | `dev-to-production.yml`    | GitHub App ID used to generate a scoped token        |
| `APP_PRIVATE_KEY`       | Secret   | `dev-to-production.yml`    | GitHub App private key for token generation          |
| `MIRROR_SSH_KEY`        | Secret   | `dev-to-production.yml`    | SSH private key for the external mirror repository   |
| `MIRROR_REPOSITORY_URL` | Variable | `dev-to-production.yml`    | URL of the external repository to mirror to          |

> ℹ️ `GITHUB_TOKEN` is automatically provided by GitHub Actions and does not need to be configured manually.
