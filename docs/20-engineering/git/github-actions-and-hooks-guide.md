> **Last updated:** 3rd September 2026  
> **Version:** 1.2  
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
    - [4.6 `generate_wiki`](#46-generate_wiki)
  - [5. GitHub Actions workflows](#5-github-actions-workflows)
    - [5.1 CI workflow (`ci.yml`)](#51-ci-workflow-ciyml)
    - [5.2 No-CI detection workflow (`detect-no-ci.yml`)](#52-no-ci-detection-workflow-detect-no-ciyml)
    - [5.3 Deploy workflow (`deploy.yml`)](#53-deploy-workflow-deployyml)
    - [5.4 Dev-to-staging workflow (`dev-to-staging.yml`)](#54-dev-to-staging-workflow-dev-to-stagingyml)
    - [5.5 Staging-to-main workflow (`staging-to-main.yml`)](#55-staging-to-main-workflow-staging-to-mainyml)
    - [5.6 VPS deploy workflow (`vps-deploy.yml`)](#56-vps-deploy-workflow-vps-deployyml)
    - [5.7 Docs-to-wiki workflow (`docs-to-wiki.yml`)](#57-docs-to-wiki-workflow-docs-to-wikiyml)
    - [5.8 Gemini PR review workflow (`gemini-pr-review.yml`)](#58-gemini-pr-review-workflow-gemini-pr-reviewyml)
  - [6. Secrets and variables](#6-secrets-and-variables)

---

## 1. Overview

The Ascension project uses a two-layered enforcement strategy:

- **Local enforcement** via Git hooks (in `.github/hooks/`) that run on the contributor's machine before a commit or push is sent to the remote.
- **Remote enforcement** via GitHub Actions workflows (in `.github/workflows/`) that run on every push or pull request in the CI environment.

Both layers rely on the same shared Python validation scripts located in `.github/scripts/`.

```
.github/
├── agents/
│   └── squad.agent.md        # GitHub Copilot coding agent instructions
├── hooks/
│   ├── pre-commit            # Runs before a commit is created
│   ├── commit-msg            # Validates the commit message format
│   └── pre-push              # Validates the branch and checks before a push
├── prompts/                  # Reusable prompt templates for Copilot agents
├── scripts/
│   ├── check_branch          # Validates the branch name format
│   ├── check_commit          # Validates the commit message format
│   ├── check_push            # Runs additional checks before a push
│   ├── gemini_commit         # Interactive AI commit assistant
│   ├── gemini_pr_review      # Automated PR review with Gemini API
│   ├── generate_wiki         # Converts docs/ into flat wiki pages
│   ├── get_commits_list      # Lists commits between dev and the current branch
│   └── reformat_code         # Formats all project code using moon
├── workflows/
│   ├── ci.yml                # Continuous Integration on every push / PR
│   ├── deploy.yml            # Build and publish artifacts on version tags
│   ├── detect-no-ci.yml      # Reusable workflow to detect no-ci prefix
│   ├── dev-to-staging.yml    # Auto create/update PR dev → staging
│   ├── docs-to-wiki.yml      # Sync docs/ to GitHub Wiki on staging-to-main completion
│   ├── gemini-pr-review.yml  # AI code review for pull requests
│   ├── staging-to-main.yml   # Merge staging → main, tag semver, changelog, mirror
│   └── vps-deploy.yml        # Automatic deployment to VPS host
├── dependabot.yml            # Dependabot configuration
├── keywords.txt              # Allowed types for branch names and commit messages
└── pull_request_template.md  # Default pull request description template
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

| Code | Meaning                                  |
| ---- | ---------------------------------------- |
| `0`  | Commit is valid                          |
| `1`  | Commit is invalid or configuration error |

### 4.3 `check_push`

**Language:** Bash  
**Usage:** `.github/scripts/check_push`

A placeholder script intended for additional pre-push validations (e.g., running tests locally before pushing).
Currently validates branch format using `check_branch`.

### 4.4 `reformat_code`

**Language:** Bash  
**Usage:** `.github/scripts/reformat_code`

Runs the code formatters for each application using the `moon` task runner:

```bash
moon run server:format   # Go (go fmt)
moon run mobile:format   # Dart (dart format)
# moon run ai:format     # Python (disabled)
```

This script is called automatically by the `pre-commit` hook and can also be run manually to format the entire codebase.

### 4.5 `get_commits_list`

**Language:** Bash  
**Usage:** `.github/scripts/get_commits_list`

A utility script that prints the list of commits between `origin/dev` and the current branch.

### 4.6 `generate_wiki`

**Language:** Python 3  
**Usage:** `.github/scripts/generate_wiki`

Converts the contents of the `docs/` directory into flat wiki pages in a `wiki/` directory, ready to be published to GitHub Wiki.

---

## 5. GitHub Actions workflows

All workflows are in `.github/workflows/`. They share the following common configuration:

- `GITHUB_ACTIONS: true` is set as an environment variable so validation scripts output GitHub-formatted annotations.
- **Concurrency** is configured per workflow and branch: a new run cancels any in-progress run for the same branch (where applicable).

### 5.1 CI workflow (`ci.yml`)

**Name:** `ascension-ci`  
**Triggers:** Every `push` and `pull_request` event (ignoring `docs/**` and `*.md`).

This workflow enforces code quality across all services. It is composed of four jobs:

#### Job: `detect_no_ci`

Calls `detect-no-ci.yml` to check if the latest commit message contains a `[no-ci]` skip tag.

#### Job: `check_commit_and_branch`

Runs if CI is not skipped.

| Step                    | Description                                                  |
| ----------------------- | ------------------------------------------------------------ |
| Checkout (full history) | Fetches all history to allow `git log` inspection            |
| Launch commit checker   | Runs `check_commit` on the latest commit message             |
| Launch branch checker   | Runs `check_branch` on the current branch (skipped for tags) |

#### Job: `check_server` (needs: `detect_no_ci`, `check_commit_and_branch`)

Validates the Go server application.

| Step             | Description                                               |
| ---------------- | --------------------------------------------------------- |
| Checkout         | Full history + recursive submodules                       |
| Set up Go        | Installs Go 1.26.0 and caches dependencies                |
| Install moon     | Sets up the moon task runner                              |
| Cache moon store | Caches `.moon/cache`                                      |
| Format check     | `moon run server:format` — fails if code is not formatted |
| Lint             | `moon run server:lint` — runs `go vet`                    |
| Build            | `moon run server:build` — compiles server binary          |
| Test             | `moon run server:test` — runs unit tests                  |

#### Job: `check_mobile` (needs: `detect_no_ci`, `check_commit_and_branch`)

Validates the Flutter mobile application.

| Step                   | Description                                               |
| ---------------------- | --------------------------------------------------------- |
| Checkout               | Full history + recursive submodules                       |
| Set up Flutter         | Installs Flutter 3.47.2 (stable channel) with cache       |
| Cache pub dependencies | Caches `~/.pub-cache` and `.dart_tool`                    |
| Install moon           | Sets up the moon task runner                              |
| Cache moon store       | Caches `.moon/cache`                                      |
| Format check           | `moon run mobile:format` — fails if code is not formatted |
| Lint                   | `moon run mobile:lint` — runs `dart analyze`              |
| Test                   | `moon run mobile:test` — runs unit tests                  |

#### Job: `check_ai` (needs: `detect_no_ci`, `check_commit_and_branch`)

Validates the Python AI application.

| Step                 | Description                                    |
| -------------------- | ---------------------------------------------- |
| Checkout             | Full history + recursive submodules            |
| Install uv           | Sets up `uv` with Python 3.11                  |
| Install moon         | Sets up the moon task runner                   |
| Cache moon store     | Caches `.moon/cache`                           |
| Cache uv environment | Caches `apps/ai/.venv`                         |
| Install dependencies | `moon run ai:install` — syncs uv dependencies  |
| Lint                 | `moon run ai:lint` — runs ruff check           |
| Test                 | `moon run ai:test` — runs pytest               |

---

### 5.2 No-CI detection workflow (`detect-no-ci.yml`)

**Name:** `ascension-detect-no-ci`  
**Triggers:** Reusable `workflow_call`.

Detects if the commit message starts with `[no-ci]`, `[skip-ci]`, etc. Outputs `skip=true` to allow calling workflows to skip subsequent jobs.

---

### 5.3 Deploy workflow (`deploy.yml`)

**Name:** `ascension-deploy`  
**Triggers:** Push of a tag matching the pattern `v*` (e.g., `v0.1.0`).

Builds and publishes production artifacts:
- **`build_and_push_server`**: Builds `apps/server/Dockerfile` (Go server) and pushes to GHCR.
- **`build_and_push_ai`**: Builds `apps/ai/Dockerfile` (Python AI worker) and pushes to GHCR.
- **`build_and_push_mobile`**: Builds Android APK using Flutter 3.47.2 and uploads build artifact.
- **`create_release`**: Downloads the APK artifact and creates a GitHub Release for tag `v*`.

---

### 5.4 Dev-to-staging workflow (`dev-to-staging.yml`)

**Name:** `ascension-dev-to-staging`  
**Triggers:**
- Scheduled cron: every Monday at midnight (`0 0 * * 1`).
- Manual dispatch (`workflow_dispatch`).

Creates or updates an automated Pull Request from `dev` to `staging`, lists included commits, and assigns `@toro-nicolas`.

---

### 5.5 Staging-to-main workflow (`staging-to-main.yml`)

**Name:** `ascension-staging-to-main`  
**Triggers:** Manual dispatch (`workflow_dispatch` with `version_bump` input: `patch`, `minor`, `major`).

1. Merges `staging` into `main`.
2. Computes the next semantic version tag (`vX.Y.Z`).
3. Generates and commits `CHANGELOG.md` via `git-cliff`.
4. Pushes the new version tag to `main` (triggering `deploy.yml`).
5. Creates a GitHub Release with release notes.
6. Mirrors the repository to external git endpoints configured in `MIRROR_REPOSITORY_URL`.

---

### 5.6 VPS deploy workflow (`vps-deploy.yml`)

**Name:** `ascension-vps-deploy`  
**Triggers:**
- `workflow_run` after successful completion of `ascension-deploy`.

Connects to the production VPS via SSH/SCP, updates `docker-compose.yml` & `docker-compose.prod.yml`, pulls latest `ascension-server:latest` and `ascension-ai:latest` images from GHCR, and restarts containers in production mode (`--profile prod`).

---

### 5.7 Docs-to-wiki workflow (`docs-to-wiki.yml`)

**Name:** `ascension-docs-to-wiki`  
**Triggers:**
- `workflow_run` after successful completion of `ascension-staging-to-main`.
- Manual dispatch (`workflow_dispatch`).

Runs `.github/scripts/generate_wiki` and pushes the flattened Markdown documentation to the repository's GitHub Wiki.

---

### 5.8 Gemini PR review workflow (`gemini-pr-review.yml`)

**Name:** `ascension-gemini-pr-review`  
**Triggers:**
- `pull_request` (opened, reopened).
- `issue_comment` (created with `/gemini-review` or `/review`).
- Manual dispatch (`workflow_dispatch`).

Executes `.github/scripts/gemini_pr_review` using Gemini API to perform automated AI code reviews on active pull requests.

---

## 6. Secrets and variables

The following secrets and variables must be configured in the GitHub repository settings:

| Name                    | Type     | Used in                                 | Description                                                     |
| ----------------------- | -------- | --------------------------------------- | --------------------------------------------------------------- |
| `GITHUB_TOKEN`          | Secret   | `deploy.yml`, `vps-deploy.yml`          | Built-in GitHub token for GHCR auth and GitHub releases         |
| `APP_ID`                | Secret   | `dev-to-staging.yml`, `staging-to-main.yml`, `gemini-pr-review.yml` | GitHub App ID for scoped token generation |
| `APP_PRIVATE_KEY`       | Secret   | `dev-to-staging.yml`, `staging-to-main.yml`, `gemini-pr-review.yml` | GitHub App private key for token generation |
| `MIRROR_SSH_KEY`        | Secret   | `staging-to-main.yml`                   | SSH private key for external mirror repositories                |
| `MIRROR_REPOSITORY_URL` | Variable | `staging-to-main.yml`                   | Comma-separated list of target repositories to mirror to        |
| `VPS_HOST`              | Secret   | `vps-deploy.yml`                        | Hostname or IP address of the deployment VPS                    |
| `VPS_USER`              | Secret   | `vps-deploy.yml`                        | SSH username for deployment VPS                                 |
| `VPS_SSH_KEY`           | Secret   | `vps-deploy.yml`                        | SSH private key for authenticating on deployment VPS            |
| `GEMINI_API_KEY`        | Secret   | `gemini-pr-review.yml`                  | API Key for Google Gemini model access                          |
