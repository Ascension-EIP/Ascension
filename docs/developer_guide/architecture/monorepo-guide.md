> **Last updated:** 18th February 2026  
> **Version:** 2.0  
> **Authors:** Gianni TUERO  
> **Status:** Done  
> {.is-success}

---

# Ascension Monorepo Architecture Guide

---

## Table of Contents

- [Overview](#overview)
- [Repository Structure](#repository-structure)
- [Why moonrepo?](#why-moonrepo)
  - [Advantages](#advantages)
  - [Trade-offs](#trade-offs)
- [moonrepo Configuration](#moonrepo-configuration)
  - [Workspace (`/.moon/workspace.yml`)](#workspace-moonworkspaceyml)
  - [Toolchain (`/.moon/toolchain.yml`)](#toolchain-moontoolchainyml)
  - [Project config (`apps/<project>/moon.yml`)](#project-config-appsprojectmoonyml)
- [Installing moon](#installing-moon)
- [Daily Workflow](#daily-workflow)
  - [Initial Clone](#initial-clone)
  - [Running Tasks](#running-tasks)
  - [Common Commands](#common-commands)
  - [Working on a Specific Service](#working-on-a-specific-service)
- [Development Environment](#development-environment)
  - [Docker Compose Setup](#docker-compose-setup)
  - [Starting Development Environment](#starting-development-environment)
- [CI/CD Architecture](#cicd-architecture)
  - [Affected-only Pipelines with moon](#affected-only-pipelines-with-moon)
  - [Full Build for Deploy](#full-build-for-deploy)
- [Best Practices](#best-practices)
  - [1. Always Define Tasks in `moon.yml`](#1-always-define-tasks-in-moonyml)
  - [2. Pin Toolchain Versions](#2-pin-toolchain-versions)
  - [3. Use `--affected` in CI](#3-use-affected-in-ci)
  - [4. Document Breaking Changes in Commits](#4-document-breaking-changes-in-commits)
  - [5. Keep `moon.yml` Minimal](#5-keep-moonyml-minimal)
- [Troubleshooting](#troubleshooting)
  - [Problem: `moon` Command Not Found](#problem-moon-command-not-found)
  - [Problem: Task Fails with Missing Binary](#problem-task-fails-with-missing-binary)
  - [Problem: Cache Is Stale](#problem-cache-is-stale)
  - [Problem: Wrong Toolchain Version](#problem-wrong-toolchain-version)
- [Additional Resources](#additional-resources)


---

## Overview

This guide explains how Ascension uses a **monorepo with [moonrepo](https://moonrepo.dev)** to organize its codebase and orchestrate tasks across all services within a single repository.

---

## Repository Structure

```
Ascension/ (Monorepo)
│
├── .moon/
│   ├── workspace.yml        # moonrepo workspace configuration
│   └── toolchain.yml        # Toolchain versions (Rust, Python…)
│
├── docker-compose.yml       # Development orchestration
├── .env.example             # Environment template
├── README.md
│
└── apps/
    ├── server/              # Rust/Axum API server
    │   ├── moon.yml         # moon project config
    │   ├── Cargo.toml
    │   ├── Dockerfile
    │   └── src/
    │
    ├── ai/                  # Python AI workers
    │   ├── moon.yml         # moon project config
    │   ├── requirements.txt
    │   ├── Dockerfile
    │   └── main.py
    │
    └── mobile/              # Flutter mobile app
        ├── moon.yml         # moon project config
        ├── pubspec.yaml
        └── lib/
```

---

## Why moonrepo?

### Advantages

1. **Single Repository**
   - All services live in one repo — no need to manage multiple remotes
   - One `git clone` gets all application code (the only submodule is `docs/`, which is optional for development)

2. **Unified Task Runner**
   - `moon run <project>:<task>` with dependency resolution and caching
   - Tasks are defined per project in `moon.yml` files

3. **Toolchain Management**
   - Rust and Python versions are pinned in `.moon/toolchain.yml`
   - Consistent across all developer machines and CI

4. **Affected-only Builds**
   - moonrepo detects which projects changed and only runs tasks on those
   - Speeds up CI significantly

5. **Docker Compose Integration**
   - `docker-compose.yml` references `apps/server` and `apps/ai` directly
   - No submodule pointer synchronization required (only `docs/` is a submodule)

### Trade-offs

- Requires [moon CLI](https://moonrepo.dev/docs/install) to be installed
- All services share the same Git history

---

## moonrepo Configuration

### Workspace (`/.moon/workspace.yml`)

```yaml
# https://moonrepo.dev/docs/config/workspace
$schema: './cache/schemas/workspace.json'

projects:
  mobile: 'apps/mobile'
  server: 'apps/server'
  ai:     'apps/ai'
```

### Toolchain (`/.moon/toolchain.yml`)

```yaml
# https://moonrepo.dev/docs/config/toolchain

rust:
  version: '1.93.1'

python:
  version: '3.14.2'
```

### Project config (`apps/<project>/moon.yml`)

Each project defines its own tasks. Examples:

**`apps/server/moon.yml`** (Rust):

```yaml
language: 'rust'

project:
  name: 'server'
  description: 'Rust/Axum backend server for Ascension'

tasks:
  dev:
    command: 'cargo'
    args: ['run']
    env:
      RUST_LOG: 'debug'
    options:
      envFile: true

  build:
    command: 'cargo'
    args: ['build']

  build-release:
    command: 'cargo'
    args: ['build', '--release']
    deps:
      - 'lint'

  test:
    command: 'cargo'
    args: ['test']

  lint:
    command: 'cargo'
    args: ['clippy', '--', '-D', 'warnings']

  format:
    command: 'cargo'
    args: ['fmt', '--check']
```

**`apps/ai/moon.yml`** (Python):

```yaml
language: 'python'

project:
  name: 'ai'
  description: 'AI service for Ascension'

tasks:
  setup:
    command: 'python'
    args: ['-m', 'venv', 'venv']

  install:
    command: 'venv/bin/pip'
    args: ['install', '-r', 'requirements.txt']
    deps:
      - 'setup'

  dev:
    command: 'venv/bin/python'
    args: ['main.py']
    deps:
      - 'install'
    options:
      envFile: true

  test:
    command: 'venv/bin/pytest'
    deps:
      - 'install'

  lint:
    command: 'venv/bin/ruff'
    args: ['check', '.']
    deps:
      - 'install'
```

**`apps/mobile/moon.yml`** (Flutter):

```yaml
language: 'unknown'

project:
  name: 'mobile'
  description: 'Flutter mobile app for Ascension'

tasks:
  install:
    command: 'flutter'
    args: ['pub', 'get']

  dev:
    command: 'flutter'
    args: ['run']
    deps:
      - 'install'

  build-android:
    command: 'flutter'
    args: ['build', 'apk']
    deps:
      - 'install'

  build-ios:
    command: 'flutter'
    args: ['build', 'ios', '--no-codesign']
    deps:
      - 'install'

  test:
    command: 'flutter'
    args: ['test']
    deps:
      - 'install'

  lint:
    command: 'flutter'
    args: ['analyze']
    deps:
      - 'install'

  format:
    command: 'dart'
    args: ['format', '.']
```

---

## Installing moon

```bash
# macOS / Linux
curl -fsSL https://moonrepo.dev/install/moon.sh | bash

# Or with proto (moon's toolchain manager)
proto install moon
```

Verify installation:

```bash
moon --version
```

---

## Daily Workflow

### Initial Clone

```bash
git clone https://github.com/Ascension-EIP/Ascension.git
cd Ascension
```

Add `--recursive` only if you need the `docs/` submodule locally (for documentation edits or AI context).

### Running Tasks

```bash
# Run a task in a specific project
moon run server:dev
moon run ai:dev
moon run mobile:dev

# Run tests
moon run server:test
moon run ai:test
moon run mobile:test

# Run lint across all projects
moon run :lint

# Run a task and all its dependents
moon run server:build-release
```

### Common Commands

```bash
# List all projects
moon project --list

# Show tasks available for a project
moon project server

# Run affected tasks only (useful in CI)
moon run :test --affected

# Check the dependency graph
moon dep-graph
```

### Working on a Specific Service

```bash
# Navigate to the project
cd apps/server

# Make changes…
# use moon or cargo/flutter/python directly

# Run its tasks via moon from anywhere in the repo
moon run server:test
moon run server:lint
```

---

## Development Environment

### Docker Compose Setup

The `docker-compose.yml` at the root references projects directly in `apps/`:

```yaml
# Located at: Ascension/docker-compose.yml

services:
  api:
    build:
      context: ./apps/server
      dockerfile: Dockerfile
    # ...

  worker:
    build:
      context: ./apps/ai
      dockerfile: Dockerfile
    # ...
```

### Starting Development Environment

```bash
# From Ascension root
docker-compose up -d

# Verify all services are running
docker-compose ps
```

---

## CI/CD Architecture

### Affected-only Pipelines with moon

**`.github/workflows/ci.yml`**:

```yaml
name: CI
on:
  push:
    branches: [main, dev]
  pull_request:

jobs:
  ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0   # required for affected detection

      - name: Install moon
        run: curl -fsSL https://moonrepo.dev/install/moon.sh | bash

      - name: Run affected tests
        run: moon run :test --affected

      - name: Run affected lint
        run: moon run :lint --affected
```

### Full Build for Deploy

```yaml
name: Deploy All Services
on:
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install moon
        run: curl -fsSL https://moonrepo.dev/install/moon.sh | bash

      - name: Build server
        run: moon run server:build-release

      - name: Build Docker images
        run: |
          docker build -t ascension-api   ./apps/server
          docker build -t ascension-worker ./apps/ai
```

---

## Best Practices

### 1. Always Define Tasks in `moon.yml`

Prefer running commands through moon rather than calling `cargo`, `flutter`, or `python` directly — this ensures caching, env loading, and dependency resolution.

### 2. Pin Toolchain Versions

Keep `.moon/toolchain.yml` up to date so all developers and CI use the same Rust/Python versions.

### 3. Use `--affected` in CI

```bash
moon run :test --affected
moon run :lint --affected
```

This avoids rebuilding and retesting services that have not changed.

### 4. Document Breaking Changes in Commits

```bash
git commit -m "feat(server): add new endpoint

BREAKING CHANGE: Requires new ENV_VAR variable in .env"
```

### 5. Keep `moon.yml` Minimal

Only define the tasks your project actually needs. Avoid duplicating configuration already handled by the toolchain (e.g., Rust version).

---

## Troubleshooting

### Problem: `moon` Command Not Found

```bash
# Re-run the installer
curl -fsSL https://moonrepo.dev/install/moon.sh | bash

# Make sure ~/.moon/bin is in your PATH
export PATH="$HOME/.moon/bin:$PATH"
```

### Problem: Task Fails with Missing Binary

Ensure dependencies are installed first:

```bash
moon run ai:install
moon run ai:dev
```

### Problem: Cache Is Stale

```bash
# Force re-run ignoring cache
moon run server:test --updateCache
```

### Problem: Wrong Toolchain Version

Check `.moon/toolchain.yml` and make sure proto/moon manages the version:

```bash
moon toolchain --list
```

---

## Additional Resources

- [moonrepo Documentation](https://moonrepo.dev/docs)
- [moon CLI Reference](https://moonrepo.dev/docs/commands/overview)
- [Deployment Guide](./deployment/README.md)
- [Architecture Overview](./README.md)

---

**Last Updated**: 2026-02-18
**Maintainer**: Ascension DevOps Team
