> **Last updated:** 10th February 2026  
> **Version:** 1.0  
> **Authors:** Nicolas  
> **Status:** Done  
> {.is-success}

---

# Git Commit Standards Guide

This document defines the standards to follow for commit messages in our project.  
Good commit conventions improve history readability, facilitate automatic changelog generation, and help team collaboration, which is particularly important in complex projects.

We use the **Conventional Commits** specification with additional rules defined below.

---

## Table of Contents

1.  [Commit message format](#1-commit-message-format)
2.  [Commit types](#2-commit-types)
3.  [Best practices](#3-best-practices)
4.  [Useful resources](#4-useful-resources)

---

## 1. Commit message format

Commit messages follow this structure:

```
<type>(<scope>): <short description>

[optional body]

[optional footer]
```

### 1.1 Basic rules

- **Language**: English
- **Case**:
  - `type` → **lowercase**
  - `description` → lowercase sentence, imperative
- **No period** at the end of the description
- Keep commits **atomic**: one intent per commit
- Body and footer are optional, but recommended when useful

### 1.2 Format details

#### Scopes

Scopes help specify **what part of the project is affected** (optional but recommended).  
Examples:  
`core`, `engine`, `network`, `ui`, `audio`, `database`, `renderer`, `physics`, `utils`, `docs`.  
**Example:**

```
fix(network): fix packet loss issue
```

#### Description rules

- Must be **short, clear, imperative**
  - Good: `fix(auth): handle missing token`
  - Bad: `fixed missing token handling`
- No final period
- Should reflect **what changed**, not **why** (the body is for that)

#### Body

The body provides **additional context**, such as:

- The motivation behind the change
- How the implementation works
- Potential impacts
- Separate paragraphs with a blank line  
   **Example body:**

```
Improved the packet processing flow by separating concerns.
This prevents desynchronization issues on unstable connections.
```

#### Footer

The footer is used for:

**Issue references**

```
Closes #42
```

**Breaking changes**  
Must start with:

```
BREAKING CHANGE:
```

**Example footer:**

```
BREAKING CHANGE: changed the serialization format for packets
```

---

## 2. Commit types

### 2.1 Main types (Conventional Commits)

| Type       | Description                                       | Example                                              |
| ---------- | ------------------------------------------------- | ---------------------------------------------------- |
| `feat`     | New feature                                       | `feat(network): add packet serialization`            |
| `fix`      | Bug fix                                           | `fix(parser): handle null pointer case`              |
| `docs`     | Documentation                                     | `docs(core): update public API documentation`        |
| `style`    | Formatting, code style, no logic change           | `style: apply clang-format to all files`             |
| `refactor` | Code refactoring                                  | `refactor(engine): simplify update loop`             |
| `test`     | Adding or modifying tests                         | `test(renderer): add unit tests for sprite batching` |
| `build`    | Build or dependency changes                       | `build: update cmake for multi-platform support`     |
| `perf`     | Performance improvements                          | `perf(audio): optimize buffer allocation`            |
| `ci`       | Continuous Integration changes                    | `ci: add linux/mac/windows workflows`                |
| `chore`    | Maintenance tasks not affecting code logic        | `chore: clean unused scripts`                        |
| `revert`   | Reverting a previous commit                       | `revert: revert "feat(network): add compression"`    |
| `add`      | Adding new files                                  | `add(utils): add string helpers file`                |
| `remove`   | Removing files or dead code                       | `remove(core): remove deprecated math module`        |
| `rename`   | Renaming files/classes                            | `rename: rename Logger to LogService`                |
| `move`     | Moving files                                      | `move: move headers to include/ directory`           |
| `merge`    | Merging branches                                  | `merge: merge "feature/ui" into "dev"`               |
| `init`     | Initialization of components or project structure | `init: initialize core project modules`              |
| `details`  | Detailed multi-line commits                       | `details:\nfix: correct memory leak in allocator`    |

---

## 3. Best practices

- Make **atomic commits**: one commit = one logical change
- Test your code before committing
- Write clear and meaningful commit messages
- Do not commit temporary files (`build`, `.cache`, etc.)

---

## 4. Useful resources

- [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
- [Git Best Practices](https://sethrobertson.github.io/GitBestPractices/)
