---
name: code-documentation
description: "AI Command: Code Documentation (/code-documentation)"
globs: ["*.dart", "*.go", "*.py", "*.ts", "*.js"]
alwaysApply: false
---

> **Last updated:** 3rd September 2026  
> **Version:** 1.0  
> **Authors:** Nicolas TORO  
> **Original language:** English  
> **Status:** Done  
> {.is-success}

---

# AI Command: Code Documentation (`/code-documentation`)

This document serves as an execution protocol for any AI model (Antigravity, Copilot, Claude Code) receiving a request to document source code (`/code-documentation` or `code-documentation`).

---

## Table of Contents

- [AI Command: Code Documentation (`/code-documentation`)](#ai-command-code-documentation-code-documentation)
  - [Table of Contents](#table-of-contents)
  - [1. Command Objective](#1-command-objective)
  - [2. File Headers](#2-file-headers)
  - [3. Code Comments (DartDoc / GoDoc / Docstrings)](#3-code-comments-dartdoc--godoc--docstrings)
  - [4. Formatting and Linting](#4-formatting-and-linting)

---

## 1. Command Objective

Standardize and update inline code documentation across the Ascension monorepo (Flutter/Dart in `apps/mobile`, Go in `apps/server`, Python in `apps/ai`).

---

## 2. File Headers

Every newly created or substantially modified source file should include a clean header describing its role and scope.

```dart
/// @file filename.dart
/// @brief Brief description of the file's role in the Ascension project.
/// @project Ascension
/// @author Author Name <email>
```

---

## 3. Code Comments (DartDoc / GoDoc / Docstrings)

Every exported class, interface, method, and function must be documented in English using the idiomatic syntax of its language:

- **Flutter / Dart (`apps/mobile`)**: Use triple-slash `///` DartDoc comments.
- **Go (`apps/server`)**: Use GoDoc comments directly preceding declarations (`// FunctionName ...`).
- **Python (`apps/ai`)**: Use Google-style docstrings (`"""..."""`).

---

## 4. Formatting and Linting

After completing code documentation updates:

```bash
# Format mobile code
moon run mobile:format

# Format server code
moon run server:format

# Format AI code
moon run ai:format
```
