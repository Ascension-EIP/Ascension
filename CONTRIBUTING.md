# Contributing to Ascension

Thank you for taking the time to contribute. Please read this guide before opening issues or pull requests.

---

## Branching

All work branches off `dev`. Branch names follow the pattern `<type>/<description>` in kebab-case (e.g. `feat/hold-detection`, `fix/upload-timeout`). Direct pushes to `main` or `dev` are blocked.

See the full rules and allowed types in the [Branch Standards Guide](docs/git/git-branch-standards-guide.md).

---

## Commits

We follow the [Conventional Commits](https://www.conventionalcommits.org) specification. Commit messages are validated by a Git hook on every commit.

See format details, allowed scopes and examples in the [Commit Standards Guide](docs/git/git-commit-standards-guide.md).

---

## Pull Requests

1. Open PRs against `dev` only.
2. Fill in the PR description: what changed, why, and how to test it.
3. CI must pass (affected tests + lint via moonrepo) before a PR can be merged.
4. At least one review approval is required.

See the full CI/CD pipeline and hook details in the [GitHub Actions & Hooks Guide](docs/git/github-actions-and-hooks-guide.md).

---

## Local setup

Follow the [Development Environment Setup](docs/developer_guide/architecture/deployment/development.md) guide to get everything running locally before submitting code.

---

## Code style

- **Rust:** `cargo fmt` + `cargo clippy` (enforced by CI).
- **Python:** `ruff` for linting and formatting (enforced by CI).
- **Dart/Flutter:** `dart format` (enforced by CI).
- **Markdown:** Prettier — see the [Markdown Guidelines](docs/guidelines/markdown-guidelines.md).
