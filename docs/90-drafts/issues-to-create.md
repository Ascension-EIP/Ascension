> **Last updated:** 16th March 2026  
> **Version:** 1.0  
> **Authors:** Nicolas  
> **Status:** Done  
> {.is-success}

---

# Issues to Create — Ascension Repo Complete Analysis


---

## Table of Contents

- [Issues to Create — Ascension Repo Complete Analysis](#issues-to-create-ascension-repo-complete-analysis)
  - [Analysis: What has been done vs. what is tracked](#analysis-what-has-been-done-vs-what-is-tracked)
  - [CI/CD Issues to Create](#cicd-issues-to-create)
    - [CI-01 — CI/CD: Main CI pipeline (GitHub Actions)](#ci-01-cicd-main-ci-pipeline-github-actions)
    - [CI-02 — CI/CD: Commit and branch validation scripts](#ci-02-cicd-commit-and-branch-validation-scripts)
    - [CI-03 — CI/CD: Deploy workflow (Docker + APK + GitHub Release)](#ci-03-cicd-deploy-workflow-docker-apk-github-release)
    - [CI-04 — CI/CD: dev-to-production workflow (promotion + semver tag + mirror)](#ci-04-cicd-dev-to-production-workflow-promotion-semver-tag-mirror)
    - [CI-05 — CI/CD: docs-to-wiki workflow](#ci-05-cicd-docs-to-wiki-workflow)
    - [CI-06 — CI/CD: Squad system (triage, assign, label cleaner, sync labels)](#ci-06-cicd-squad-system-triage-assign-label-cleaner-sync-labels)
    - [CI-07 — CI/CD: Squad AI PR Review (automatic GPT-4o code review)](#ci-07-cicd-squad-ai-pr-review-automatic-gpt-4o-code-review)
    - [CI-08 — CI/CD: Squad PR routing (automatic PR labeling by domain)](#ci-08-cicd-squad-pr-routing-automatic-pr-labeling-by-domain)
    - [CI-09 — CI/CD: Dependabot (automatic dependency updates)](#ci-09-cicd-dependabot-automatic-dependency-updates)
    - [CI-10 — CI/CD: Git hooks (commit-msg, pre-commit, pre-push)](#ci-10-cicd-git-hooks-commit-msg-pre-commit-pre-push)
    - [CI-11 — CI/CD: Moon monorepo task runner (format, lint, build, test)](#ci-11-cicd-moon-monorepo-task-runner-format-lint-build-test)
  - [Other already-done but untracked issues](#other-already-done-but-untracked-issues)
    - [BACK-01 — SERVER: Full User CRUD](#back-01-server-full-user-crud)
    - [BACK-02 — SERVER: JWT authentication middleware](#back-02-server-jwt-authentication-middleware)
    - [MOBILE-01 — MOBILE: Settings page (backend URL configuration)](#mobile-01-mobile-settings-page-backend-url-configuration)
    - [MOBILE-02 — MOBILE: Auth login and register pages (scaffold)](#mobile-02-mobile-auth-login-and-register-pages-scaffold)
  - [Summary](#summary)

---



> Document generated on 03/09/2026. Do not create any issue without prior approval.

---

## Analysis: What has been done vs. what is tracked

Before listing the new issues, here are the **already implemented features not tracked** in the backlog:

| What is done | Issue tracked? |
|---|---|
| Main CI pipeline (check commit, branch, format, lint, build, test) | ❌ Not tracked |
| `check_commit` and `check_branch` scripts (Python) | ❌ Not tracked |
| `docs-to-wiki` workflow | ❌ Not tracked |
| `deploy` workflow (Docker build + APK + GitHub Release) | ❌ Not tracked |
| `dev-to-production` workflow (merge dev→main + semver tag + mirror) | ❌ Not tracked |
| Squad system (triage, assign, label cleaner, PR review, sync labels) | ❌ Not tracked |
| Squad AI PR review (GPT-4o via GitHub Models) | ❌ Not tracked |
| Dependabot (github-actions, cargo, pub, pip) | ❌ Not tracked |
| Git hooks (commit-msg, pre-commit, pre-push) | ❌ Not tracked |
| Full User CRUD in the server | ❌ Not tracked |
| JWT auth middleware in the server | ❌ Not tracked |
| Settings page in the mobile app (backend URL configuration) | ❌ Not tracked |
| Auth login/register pages (scaffold) | ❌ Not tracked |
| Moon monorepo task runner (format, lint, build, test for all 3 apps) | ❌ Not tracked |

---

## CI/CD Issues to Create

---

### CI-01 — CI/CD: Main CI pipeline (GitHub Actions)

**Suggested labels:** `CI/CD`, `Setup`

**Description:**

Set up the main CI workflow (`ascension-ci`) that runs on every `push` and `pull_request`. The pipeline orchestrates format, lint, build and test validation for all three monorepo applications (Rust, Flutter, Python).

**Features implemented:**
- Detection of the `[no-ci]` prefix to skip all checks
- Commit message format validation (via `check_commit`)
- Branch name format validation (via `check_branch`)
- `check_server` job: rustfmt, clippy, release build, tests (with Cargo + moon cache)
- `check_mobile` job: flutter format, flutter analyze, flutter test (with pub + moon cache)
- `check_ai` job: black lint, pytest (with conda + moon cache)
- Concurrency: duplicate run cancellation on the same branch

**Definition of Done:**
- [x] The `ascension-ci` workflow triggers on `push` and `pull_request`
- [x] `check_server`, `check_mobile`, `check_ai` jobs run in parallel
- [x] Cargo, pub and conda caches are functional
- [x] The `[no-ci]` prefix skips all checks
- [x] Jobs depend on `detect_no_ci` and `check_commit_and_branch`
- [x] CI is documented in the developer guide

---

### CI-02 — CI/CD: Commit and branch validation scripts

**Suggested labels:** `CI/CD`, `Setup`

**Description:**

Implementation of two Python scripts (`.github/scripts/check_commit` and `.github/scripts/check_branch`) that validate commit message format and branch name format respectively, according to the project conventions.

**Enforced conventions:**
- Commits: `<type>(<scope>): <description>` with types listed in `.github/keywords.txt`
- Branches: `main`, `dev` or `<type>/<kebab-case-description>`
- Allowed types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `tests`, `build`, `perf`, `ci`, `chore`, `revert`, `add`, `remove`, `rename`, `move`, `merge`, `init`, `details`, `dependabot`, `agents`, `temp`

**Definition of Done:**
- [x] `check_commit` validates the `<type>(<scope>): <description>` format
- [x] `check_commit` allows `Merge ...` commits without validation
- [x] `check_branch` accepts `main` and `dev` as-is
- [x] `check_branch` validates `<type>/<kebab-case>`
- [x] Errors are formatted as GitHub Actions annotations (`::error::`)
- [x] Scripts are executable and used by the CI
- [x] `.github/keywords.txt` contains all allowed commit types

---

### CI-03 — CI/CD: Deploy workflow (Docker + APK + GitHub Release)

**Suggested labels:** `CI/CD`, `Build`

**Description:**

Set up the `ascension-deploy` workflow that triggers on `v*` tags. It builds and pushes the server Docker image to GHCR, builds the Android APK in release mode, and automatically creates a GitHub Release with the artifacts.

**Jobs:**
- `build_and_push_server`: Multi-stage Docker build of the Rust server → push to GHCR with `:vX.Y.Z` and `:latest` tags
- `build_and_push_mobile`: Flutter release APK build → upload GitHub Actions artifact
- `create_release`: Creates the GitHub Release with auto-generated release notes and the APK as a release asset

**Definition of Done:**
- [x] The workflow triggers on `v*` tags
- [x] The server Docker image is pushed to GHCR with the correct tag
- [x] The Android release APK is built and attached to the GitHub Release
- [x] GitHub Release notes are auto-generated (`generate_release_notes: true`)
- [x] Docker BuildX cache (GHA) is configured to speed up builds
- [ ] The `build_and_push_ai` job is uncommented and functional (currently disabled)

---

### CI-04 — CI/CD: dev-to-production workflow (promotion + semver tag + mirror)

**Suggested labels:** `CI/CD`, `Setup`

**Description:**

Set up the manual `ascension-dev-to-production` workflow that automates the promotion from `dev` to `main`, the creation of an auto-incremented SemVer tag, and the mirroring of the repo to an external repository.

**Jobs:**
- `merge_branch`: Merges `dev` → `main` via GitHub App token (to bypass branch protections)
- `create_tag`: Computes the next `vX.Y.(Z+1)` tag and pushes it on `main`
- `mirror_repository`: Mirrors the repo to an external SSH repository (Epitech intranet)

**Definition of Done:**
- [x] The `dev → main` merge works with the GitHub App token
- [x] The SemVer tag is auto-computed from the last existing `v*` tag
- [x] SSH mirror to the external repository is functional
- [x] `APP_ID`, `APP_PRIVATE_KEY`, and `MIRROR_SSH_KEY` secrets are configured
- [x] The `MIRROR_REPOSITORY_URL` variable is configured in the repo settings

---

### CI-05 — CI/CD: docs-to-wiki workflow

**Suggested labels:** `CI/CD`, `Documentation`

**Description:**

Set up the `ascension-docs-to-wiki` workflow that automatically synchronizes the content of the `docs/` folder to the GitHub Wiki on every push to `main`.

**How it works:**
- The `generate_wiki` script converts Markdown files from `docs/` into wiki pages with flat naming (`folder-subfolder-file.md`)
- Special files (`README.md`, `CONTRIBUTING.md`, etc.) are mapped to standard wiki pages (`Home`, `HOW-TO-CONTRIBUTE`, etc.)
- Internal links are rewritten to point to wiki pages

**Definition of Done:**
- [x] The workflow triggers on `push` to `main` in `docs/**`
- [x] The `generate_wiki` script correctly generates the wiki from `docs/`
- [x] Special pages (`Home`, `HOW-TO-CONTRIBUTE`) are correctly created
- [x] Internal links are rewritten in generated wiki pages
- [x] The wiki is up to date after each push to main

---

### CI-06 — CI/CD: Squad system (triage, assign, label cleaner, sync labels)

**Suggested labels:** `CI/CD`, `Setup`

**Description:**

Set up the Squad system composed of several GitHub Actions workflows to automate issue triage, member assignment, label cleanup, and label synchronization from the team roster.

**Implemented workflows:**
- `squad-triage`: When the `squad` label is applied, analyzes the issue and automatically assigns it to the right member via keyword matching. Supports `@copilot` (Coding Agent) with a capability profile.
- `squad-issue-assign`: When a `squad:<member>` label is applied, adds the GitHub assignment and posts an acknowledgment comment.
- `squad-label-cleaner`: Enforces mutual exclusivity for the `go:`, `release:`, `type:`, `priority:` namespaces. Auto-applies `release:backlog` on `go:yes`.
- `sync-squad-labels`: Synchronizes GitHub labels from `.squad/team.md` (squad, go, release, type, priority, and signal labels).

**Definition of Done:**
- [x] `squad-triage` correctly assigns issues by domain
- [x] `squad-issue-assign` posts a comment and assigns the right member
- [x] `squad-label-cleaner` removes conflicting labels in managed namespaces
- [x] `sync-squad-labels` creates/updates all labels from the roster
- [x] The `go:needs-research` label is auto-applied at triage
- [x] The `release:backlog` label is auto-applied on `go:yes`
- [x] `@copilot` can be automatically assigned (`COPILOT_ASSIGN_TOKEN` secret configured)

---

### CI-07 — CI/CD: Squad AI PR Review (automatic GPT-4o code review)

**Suggested labels:** `CI/CD`, `AI`

**Description:**

Set up the `squad-ai-pr-review` workflow that triggers an automatic GPT-4o code review (via GitHub Models API) on every PR open or update. Each squad agent reviews the files belonging to their domain.

**How it works:**
- On PR open/update, the workflow analyzes the changed files
- For each impacted domain (AI, Server, Mobile, DevOps, Docs, Tests, DB/Infra), the corresponding agent generates a review via GPT-4o
- The review is posted (or updated) as a dedicated per-agent comment
- Uses only `GITHUB_TOKEN` (Copilot Pro unlocks premium models)

**Domain routing:**
- `apps/ai/**` → Quentin (AI / Python)
- `apps/server/**` → Renaud (Rust / API)
- `apps/mobile/**` → Romaric (Flutter / Mobile)
- `.github/**`, `docker*` → Arthur (DevOps / CI)
- `docs/**` → Darius (Documentation)
- `**/test*/**` → Ridjan (Testing)
- `**/migrations/**` → Alexandra (Database / Infra)

**Definition of Done:**
- [x] The workflow triggers on `opened`, `synchronize`, `reopened`
- [x] Each impacted domain receives a dedicated AI review
- [x] Review comments are updated (not duplicated on re-runs)
- [x] File-to-agent routing is documented
- [x] Works without additional secrets (GITHUB_TOKEN only)

---

### CI-08 — CI/CD: Squad PR routing (automatic PR labeling by domain)

**Suggested labels:** `CI/CD`

**Description:**

Set up the `squad-pull-request-review` workflow that analyzes the files changed in a PR and automatically applies `squad:<agent>` labels to route the review to the right domain experts.

**Definition of Done:**
- [x] The workflow labels PRs with the corresponding `squad:<agent>` labels
- [x] Stale labels from previous runs are removed
- [x] A routing comment is posted/updated on the PR with the domain summary table
- [x] If more than 2 domains are touched, `squad:eric` (Architecture) is added
- [x] Missing `squad:*` labels are auto-created

---

### CI-09 — CI/CD: Dependabot (automatic dependency updates)

**Suggested labels:** `CI/CD`, `Setup`

**Description:**

Configuration of Dependabot to automatically update dependencies across the four ecosystems of the monorepo, targeting the `dev` branch.

**Configured ecosystems:**
- `github-actions` (root `/`)
- `cargo` (`/apps/server`)
- `pub` (`/apps/mobile`)
- `pip` (`/apps/ai`)

**Schedule:** Every Monday at 09:00 (Europe/Paris)

**Definition of Done:**
- [x] `.github/dependabot.yml` is configured for all 4 ecosystems
- [x] Dependabot PRs target the `dev` branch
- [x] Weekly schedule is configured
- [x] Dependabot PRs go through the CI before merge

---

### CI-10 — CI/CD: Git hooks (commit-msg, pre-commit, pre-push)

**Suggested labels:** `CI/CD`, `Setup`

**Description:**

Set up local git hooks (in `.github/hooks/`) allowing developers to validate their commits and branches before pushing, reusing the same scripts as the CI.

**Hooks:**
- `commit-msg`: Validates the commit message format via `check_commit`
- `pre-commit`: Can run local checks before committing
- `pre-push`: Can run local checks before pushing

**Definition of Done:**
- [x] `commit-msg`, `pre-commit`, `pre-push` hooks are present in `.github/hooks/`
- [ ] A hook installation script is provided (e.g. `just install-hooks` or a shell script)
- [ ] `pre-commit` and `pre-push` hooks are implemented (currently empty)
- [ ] The README explains how to install and use the hooks
- [ ] Hooks reuse the same scripts as the CI (`check_commit`, `check_branch`)

---

### CI-11 — CI/CD: Moon monorepo task runner (format, lint, build, test)

**Suggested labels:** `CI/CD`, `Setup`, `Build`

**Description:**

Configuration of the Moon task runner to orchestrate development tasks (`format`, `lint`, `build`, `test`, `dev`) across all three monorepo applications, with environment variable management and input/output configuration for caching.

**Tasks configured per app:**
- `server`: `format`, `format-check`, `lint`, `build`, `build-release`, `test`, `dev`
- `mobile`: `format`, `format-check`, `lint`, `test`, `dev`
- `ai`: `install`, `format`, `lint`, `test`, `dev`

**Definition of Done:**
- [x] `moon run server:format` / `mobile:format` / `ai:format` work correctly
- [x] `moon run server:lint` / `mobile:lint` / `ai:lint` work correctly
- [x] `moon run server:build-release` works correctly
- [x] `moon run server:test` / `mobile:test` / `ai:test` work correctly
- [x] Environment variables are correctly passed to tasks
- [x] Moon cache is used in the CI

---

## Other already-done but untracked issues

---

### BACK-01 — SERVER: Full User CRUD

**Suggested labels:** `Server`

**Description:**

Implementation of a complete CRUD for the `User` resource in the Rust/Axum backend, following a hexagonal architecture (domain / inbound / outbound / usecase).

**Implemented endpoints:**
- `POST /api/v1/users` — Create a user
- `GET /api/v1/users/:id` — Get a user by ID
- `GET /api/v1/users` — List users (with pagination)
- `PUT /api/v1/users/:id` — Update a user
- `DELETE /api/v1/users/:id` — Delete a user

**Definition of Done:**
- [x] All 5 CRUD endpoints are implemented and functional
- [x] The `User` model is defined with `Username`, `EmailAddress`, `Password`, `Role` value objects
- [x] Domain errors (`DuplicateEmail`, `UserNotFound`, etc.) are typed
- [x] PostgreSQL adapter is implemented via SQLx (`postgresql.rs`)
- [x] SQL queries are defined (insert, select, update, delete, list with pagination)
- [x] Unit tests cover the user model and service
- [x] Pagination is functional (`page`, `per_page`)

---

### BACK-02 — SERVER: JWT authentication middleware

**Suggested labels:** `Server`

**Description:**

Implementation of a JWT authentication middleware in the Axum backend. The middleware extracts and validates the Bearer token from the `Authorization` header, then injects the user identity into the request context.

**Definition of Done:**
- [x] The middleware verifies the `Authorization: Bearer <token>` header
- [x] An invalid or expired token returns `401 Unauthorized`
- [x] The user identity is injected via Axum extensions
- [x] Protected routes use the middleware
- [x] An `AuthService` is implemented for token validation
- [x] Error handling is typed (`AuthError`)

---

### MOBILE-01 — MOBILE: Settings page (backend URL configuration)

**Suggested labels:** `Mobile`

**Description:**

Implementation of the Settings page in the Flutter application, allowing the user to configure the backend URL. The URL is persisted locally via `SharedPreferences` and used by `ApiService` for all requests.

**Definition of Done:**
- [x] The Settings page is accessible from the app header
- [x] A text field allows entering the backend URL (e.g. `http://192.168.1.x:8080`)
- [x] The URL is persisted via `SharedPreferences`
- [x] `ApiService` loads the persisted URL on startup
- [x] A visual indicator (✓ icon) confirms the save
- [x] The URL can also be set at compile time via `--dart-define=BACKEND_URL=...`

---

### MOBILE-02 — MOBILE: Auth login and register pages (scaffold)

**Suggested labels:** `Mobile`

**Description:**

Creation of the authentication page scaffolds (`LoginPage` and `RegisterPage`) in the Flutter application. These pages are placeholders pending the full implementation of the JWT authentication flow.

**Definition of Done:**
- [x] `LoginPage` and `RegisterPage` are created and accessible via navigation
- [ ] The login form is functional (email + password)
- [ ] The register form is functional (username + email + password)
- [ ] Pages call `ApiService` for `POST /auth/login` and `POST /auth/register`
- [ ] API errors are displayed to the user
- [ ] Post-login navigation to the main page is implemented

> **Note:** Pages exist but are stubs (`Login coming soon!`). Issue AUTH #62 covers the full implementation.

---

## Summary

| ID | Title | Category | Actual status |
|---|---|---|---|
| CI-01 | Main CI pipeline | CI/CD | ✅ Done, untracked |
| CI-02 | check_commit / check_branch scripts | CI/CD | ✅ Done, untracked |
| CI-03 | Deploy workflow | CI/CD | ✅ Done, untracked |
| CI-04 | dev-to-production workflow | CI/CD | ✅ Done, untracked |
| CI-05 | docs-to-wiki workflow | CI/CD | ✅ Done, untracked |
| CI-06 | Squad system (triage + assign + labels) | CI/CD | ✅ Done, untracked |
| CI-07 | Squad AI PR Review (GPT-4o) | CI/CD | ✅ Done, untracked |
| CI-08 | Squad PR routing | CI/CD | ✅ Done, untracked |
| CI-09 | Dependabot | CI/CD | ✅ Done, untracked |
| CI-10 | Git hooks | CI/CD | ⚠️ Partial (empty hooks) |
| CI-11 | Moon monorepo tasks | CI/CD | ✅ Done, untracked |
| BACK-01 | Full User CRUD backend | Server | ✅ Done, untracked |
| BACK-02 | JWT middleware backend | Server | ✅ Done, untracked |
| MOBILE-01 | Settings page | Mobile | ✅ Done, untracked |
| MOBILE-02 | Auth pages scaffold | Mobile | ⚠️ Partial (stubs) |
