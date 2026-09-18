---
id: 8bea3644-9e6b-411d-8d24-ad08cd149b82
---

:::success
**Version:** 1.0\
**Original language:** English
:::

---

# AI Agent Configuration & Tools Architecture

This document provides the complete architecture, configuration standards, and user guide for AI agent integrations across the Ascension monorepo. It explains how instructions, rules, commands, skills, and Model Context Protocol (MCP) servers are centralized and shared among **Google Antigravity 2.0**, **Claude Code**, and **GitHub Copilot**.

---

## Table of Contents

- [AI Agent Configuration & Tools Architecture](#ai-agent-configuration--tools-architecture)
  - [Table of Contents](#table-of-contents)
  - [1\. Architecture & Philosophy](#1-architecture--philosophy)
  - [2\. Canonical Root:](#2-canonical-root-agents) `.agents/`
  - [3\. Command Reference](#3-command-reference)
    - [3.1](#31-commit) `/commit`
    - [3.2](#32-documentation) `/documentation`
    - [3.3](#33-documentation-files) `/documentation-files`
    - [3.4](#34-code-documentation) `/code-documentation`
    - [3.5](#35-forui-ui-polish) `/forui-ui-polish`
    - [3.6](#36-graphify) `/graphify`
    - [3.7](#37-update-docs) `/update-docs`
  - [4\. Rules Reference](#4-rules-reference)
    - [4.1 Markdown Guidelines (](#41-markdown-guidelines-markdownmd)`markdown.md`[)](#41-markdown-guidelines-markdownmd)
    - [4.2 Forui UI Polish (](#42-forui-ui-polish-forui-ui-polishmd)`forui-ui-polish.md`[)](#42-forui-ui-polish-forui-ui-polishmd)
    - [4.3 Code Documentation (](#43-code-documentation-code-documentationmd)`code-documentation.md`[)](#43-code-documentation-code-documentationmd)
  - [5\. Skills Reference](#5-skills-reference)
    - [5.1 Densho (](#51-densho-densho)`densho`[)](#51-densho-densho)
    - [5.2 Graphify (](#52-graphify-graphify)`graphify`[)](#52-graphify-graphify)
    - [5.3 Forui (](#53-forui-forui)`forui`[)](#53-forui-forui)
  - [6\. Model Context Protocol (MCP) Configuration](#6-model-context-protocol-mcp-configuration)
  - [7\. Multi-Tool Integration & Symlink Matrix](#7-multi-tool-integration--symlink-matrix)
    - [7.1 Symlink Mapping Table](#71-symlink-mapping-table)
    - [7.2 Google Antigravity 2.0 Integration](#72-google-antigravity-20-integration)
    - [7.3 Claude Code Integration](#73-claude-code-integration)
    - [7.4 GitHub Copilot Integration](#74-github-copilot-integration)
  - [8\. Maintenance & Best Practices](#8-maintenance--best-practices)

---

## 1\. Architecture & Philosophy

Development teams often utilize different AI programming assistants based on developer preference, operating system, and IDE choice. Within the Ascension project:

- **Google Antigravity 2.0** is used as an AI-first development environment and desktop agent orchestrator.
- **Claude Code** is utilized for autonomous terminal and CLI-based refactoring workflows.
- **GitHub Copilot** is used inside Visual Studio Code and JetBrains IDEs.

To prevent drift, duplicated documentation, and conflicting AI behaviors, the repository enforces a **Single Source of Truth** pattern:

1. All canonical instructions, commands, rules, skills, and MCP definitions live exclusively in `.agents/`.
2. Tool-specific configurations (`CLAUDE.md`, `.claude/`, `GEMINI.md`, `.github/copilot-instructions.md`, `.github/prompts/`, `.vscode/mcp.json`, etc.) are lightweight **relative symbolic links** pointing back into `.agents/`.
3. Updating an instruction or command in `.agents/` instantly updates the behavior for all three AI assistants without extra build steps or manual synchronization.

---

## 2\. Canonical Root: `.agents/`

The `.agents/` directory is organized into five specialized modules:

```text
.agents/
├── instructions.md                # Master system instructions & project vision
├── commands/                      # Slash commands and operational runbooks
│   ├── commit.md                  # /commit
│   ├── documentation.md           # /documentation
│   ├── documentation-files.md     # /documentation-files
│   ├── code-documentation.md      # /code-documentation
│   ├── forui-ui-polish.md         # /forui-ui-polish
│   ├── graphify.md                # /graphify
│   └── update-docs.md             # /update-docs
├── rules/                         # Enforced ambient and path-scoped rules
│   ├── markdown.md                # Repository Markdown style guide
│   ├── forui-ui-polish.md         # Symlink -> ../commands/forui-ui-polish.md
│   └── code-documentation.md      # Symlink -> ../commands/code-documentation.md
├── skills/                        # Complex progressive-disclosure runbooks
│   ├── densho/                    # Densho knowledge base MCP skill
│   ├── graphify/                  # Knowledge graph query & indexing skill
│   └── forui/                     # Forui Flutter UI library & 12 focused subskills
├── mcp/                           # Model Context Protocol scripts & servers
│   ├── graphify-mcp.sh            # Universal stdio launcher for Graphify MCP
│   └── mcp.json                   # Master MCP server definition
├── workflows -> commands          # Antigravity native workflow discovery symlink
└── mcp_config.json -> mcp/mcp.json# Antigravity native MCP configuration symlink
```

---

## 3\. Command Reference

Commands are structured task prompts that can be triggered on demand using slash commands (e.g., `/commit`, `/graphify`) across Antigravity, Claude Code, and GitHub Copilot.

### 3.1 `/commit`

- **Source:** `.agents/commands/commit.md`
- **Purpose:** Generates atomic conventional commit messages following the project's commit guidelines.
- **Trigger:** Type `/commit` after staging files with `git add`.
- **Reference Document:** `docs/developer/git/git-commit-standards-guide.md`
- **Behavior:**
  - Evaluates staged changes using `git diff --staged`.
  - Determines the appropriate type (`feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, etc.) and scope (`mobile`, `server`, `ai`, `docs`, etc.).
  - Writes in lowercase imperative mood with no trailing period.
  - Commits locally using `git commit -m` without pushing.

### 3.2 `/documentation`

- **Source:** `.agents/commands/documentation.md`
- **Purpose:** Full checklist and auditing protocol for creating or updating Markdown documentation files.
- **Trigger:** Type `/documentation` when editing docs or creating new guides.
- **Reference Document:** `docs/developer/guidelines/markdown-guidelines.md`
- **Key Verifications:**
  - Mandatory Densho status header block (`:::success`, `:::warning`, `:::danger`).
  - Strict heading hierarchy without skipping levels.
  - Horizontal rules (`---`) before every `##` heading.
  - Automatic Table of Contents.
  - Checks `.docignore` before performing modifications.

### 3.3 `/documentation-files`

- **Source:** `.agents/commands/documentation-files.md`
- **Purpose:** Fast-path validation protocol focused strictly on markdown file structure and naming conventions.
- **Trigger:** Type `/documentation-files` for quick structure compliance reviews.

### 3.4 `/code-documentation`

- **Source:** `.agents/commands/code-documentation.md`
- **Purpose:** Generates idiomatic code comments and file headers across the monorepo.
- **Trigger:** Type `/code-documentation` when authoring or reviewing code.
- **Conventions:**
  - **Flutter/Dart (**`apps/mobile`**):** Triple-slash `///` DartDoc comments.
  - **Go (**`apps/server`**):** Standard GoDoc comments preceding exported declarations (`// FunctionName ...`).
  - **Python (**`apps/ai`**):** Google-style docstrings (`"""..."""`).
  - **Safety Check:** Enforces Section 3 of `instructions.md` (never write AI names as file author).

### 3.5 `/forui-ui-polish`

- **Source:** `.agents/commands/forui-ui-polish.md`
- **Purpose:** Enforces the Ascension visual polish standards for Flutter development.
- **Trigger:** Type `/forui-ui-polish` or triggered automatically via ambient rules when editing `apps/mobile/lib/**/*.dart`.
- **Pillars:**
  1. **Iconography:** Strict use of `FLucideIcons` (no `Icons.*` from Flutter Material).
  2. **Micro-Interactions:** Declarative entry transitions with `flutter_animate` (fadeIn + slideY).
  3. **Loading States:** Shimmer skeletons via `Skeletonizer` (no full-screen circular progress spinners).

### 3.6 `/graphify`

- **Source:** `.agents/commands/graphify.md`
- **Purpose:** Queries and synchronizes the project's knowledge graph located in `graphify-out/`.
- **Trigger:** Type `/graphify` for architecture questions or post-refactor graph updates.
- **Protocols:**
  - Targeted queries: `graphify query "<question>"` or MCP `query_graph`.
  - Relationship inspection: `graphify path "<CompA>" "<CompB>"`.
  - Concept explanation: `graphify explain "<concept>"`.
  - Post-change synchronization: `graphify update .`.

### 3.7 `/update-docs`

- **Source:** `.agents/commands/update-docs.md`
- **Purpose:** Identifies modified source code and automatically brings relevant documentation and knowledge graphs into sync.
- **Trigger:** Type `/update-docs` prior to opening pull requests.

---

## 4\. Rules Reference

Rules provide persistent guidelines that AI assistants load into their context to constrain output and prevent regressions.

### 4.1 Markdown Guidelines (`markdown.md`)

- **Scope:** All `*.md` files.
- **Standard:** CommonMark / GitHub Flavored Markdown (GFM).
- **Enforcements:**
  - Filenames must be `kebab-case`.
  - Densho status headers must declare version and original language.
  - Horizontal rules before every major heading (`##`).
  - Accessibility constraints (alt text for images, table headers, code fence language tags).

### 4.2 Forui UI Polish (`forui-ui-polish.md`)

- **Scope:** `apps/mobile/lib/**/*.dart`
- **Mode:** Always active on mobile UI tasks.
- **Enforcements:** Prevents usage of raw Material icons and enforces consistent animations and skeleton loading patterns.

### 4.3 Code Documentation (`code-documentation.md`)

- **Scope:** `*.dart`, `*.go`, `*.py`, `*.ts`, `*.js`
- **Mode:** Triggered on code authoring and modifications.
- **Enforcements:** File header metadata, language-specific comment formats, and strict author attribution rules.

---

## 5\. Skills Reference

Skills are modular, progressive-disclosure directories containing a `SKILL.md` file with frontmatter metadata, examples, and reference manuals. They are loaded on demand by the agent when relevant tasks are detected.

### 5.1 Densho (`densho`)

- **Path:** `.agents/skills/densho/SKILL.md`
- **Description:** Enables AI agents to read, create, search, organize, and comment on documentation pages within a Densho workspace via its MCP server.
- **Safety:** Enforces version token verification (`expectedVersion`) before applying full-body page updates to avoid overwriting teammate changes.

### 5.2 Graphify (`graphify`)

- **Path:** `.agents/skills/graphify/SKILL.md`
- **Description:** Enables agents to navigate the AST and semantic knowledge graph of the codebase, inspect god nodes, evaluate cross-component dependencies, and execute graph traversal algorithms.
- **References:** Includes deep-dive guides for exports, query strategies, extraction specifications, and hooks.

### 5.3 Forui (`forui`)

- **Path:** `.agents/skills/forui/SKILL.md`
- **Description:** Complete reference for the 40+ accessible widgets of the Forui design system for Flutter.
- **Subskills:**
  - `forui-best-practices`: Architecture and review standards.
  - `forui-cli`: CLI generator workflows (`dart run forui init`, etc.).
  - `forui-content-components`: Display widgets (FCard, FBadge, FAvatar, etc.).
  - `forui-controls`: Controller lifecycle and state management.
  - `forui-forms-inputs`: Inputs, checkboxes, selects, pickers, and forms.
  - `forui-hooks-icons-localization`: FLucideIcons and flutter\_hooks integration.
  - `forui-layout-navigation`: FScaffold, FHeader, FBottomNavigationBar, etc.
  - `forui-overlays-feedback`: FDialog, FSheet, FToast, FPopover, and tooltips.
  - `forui-setup`: Initial installation and app root wiring.
  - `forui-styling`: Custom styles and theme variant definitions.
  - `forui-theming`: Theme presets and palette customization.
  - `forui-widget-previews`: Flutter Widget Previewer integration and testing.

---

## 6\. Model Context Protocol (MCP) Configuration

The monorepo provides local stdio MCP server support for **Graphify** via a portable wrapper script:

- **Runner Script:** `.agents/mcp/graphify-mcp.sh`
  - Dynamically discovers the repository root using Git (`git rev-parse --show-toplevel`).
  - Ensures `graphify-out/graph.json` exists so the server does not fail on startup.
  - Automatically identifies available Python environments (`graphify` shebang, `uv tool run`, or system `python3`).
- **Master Definition (**`.agents/mcp/mcp.json`**):**

  ```json
  {
    "mcpServers": {
      "graphify": {
        "command": "./.agents/mcp/graphify-mcp.sh"
      }
    }
  }
  ```

---

## 7\. Multi-Tool Integration & Symlink Matrix

### 7.1 Symlink Mapping Table

| Purpose | Canonical File in `.agents/` | Antigravity 2.0 | Claude Code | GitHub Copilot |
| --- | --- | --- | --- | --- |
| **System Instructions** | `.agents/instructions.md` | `GEMINI.md`, `AGENTS.md` | `CLAUDE.md`, `.claude/instructions.md` | `.github/copilot-instructions.md` |
| **Commit Command** | `.agents/commands/commit.md` | `/commit` (via `workflows/`) | `.claude/commands/commit.md` | `.github/prompts/commit.prompt.md` |
| **Documentation Command** | `.agents/commands/documentation.md` | `/documentation` | `.claude/commands/documentation.md` | `.github/prompts/documentation.prompt.md` |
| **Doc Files Command** | `.agents/commands/documentation-files.md` | `/documentation-files` | `.claude/commands/documentation-files.md` | `.github/prompts/documentation-files.prompt.md` |
| **Code Doc Command** | `.agents/commands/code-documentation.md` | `/code-documentation` | `.claude/commands/code-documentation.md` | `.github/prompts/code-documentation.prompt.md` |
| **UI Polish Command** | `.agents/commands/forui-ui-polish.md` | `/forui-ui-polish` | `.claude/commands/forui-ui-polish.md` | `.github/prompts/forui-ui-polish.prompt.md` |
| **Graphify Command** | `.agents/commands/graphify.md` | `/graphify` | `.claude/commands/graphify.md` | `.github/prompts/graphify.prompt.md` |
| **Update Docs Command** | `.agents/commands/update-docs.md` | `/update-docs` | `.claude/commands/update-docs.md` | `.github/prompts/update-docs.prompt.md` |
| **Markdown Rule** | `.agents/rules/markdown.md` | `.agents/rules/markdown.md` | `.claude/rules/markdown.md` | `.github/instructions/markdown.instructions.md` |
| **UI Polish Rule** | `.agents/rules/forui-ui-polish.md` | `.agents/rules/forui-ui-polish.md` | `.claude/rules/forui-ui-polish.md` | `.github/instructions/forui-ui-polish.instructions.md` |
| **Code Doc Rule** | `.agents/rules/code-documentation.md` | `.agents/rules/code-documentation.md` | `.claude/rules/code-documentation.md` | `.github/instructions/code-documentation.instructions.md` |
| **Densho Skill** | `.agents/skills/densho` | `.agents/skills/densho` | `.claude/skills/densho` | Referenced via prompt/context |
| **Forui Skill** | `.agents/skills/forui` | `.agents/skills/forui` | `.claude/skills/forui` | Referenced via prompt/context |
| **Graphify Skill** | `.agents/skills/graphify` | `.agents/skills/graphify` | `.claude/skills/graphify` | Referenced via prompt/context |
| **MCP Server** | `.agents/mcp/mcp.json` | `.agents/mcp_config.json` | `.mcp.json` | `.vscode/mcp.json` |

### 7.2 Google Antigravity 2.0 Integration

- **Customization Root:** Discovers `.agents/` natively at the project root.
- **Rules:** Automatically discovers and evaluates all files in `.agents/rules/*.md`.
- **Skills:** Automatically discovers all skills matching `.agents/skills/*/SKILL.md`.
- **Workflows:** Discovers workflows in `.agents/workflows/`, which points via a symlink to `.agents/commands/`.
- **MCP:** Loaded via `.agents/mcp_config.json` pointing to `.agents/mcp/mcp.json`.

### 7.3 Claude Code Integration

- **Project Prompt:** Automatically reads `CLAUDE.md` and `.claude/instructions.md` at session start.
- **Commands:** Loads slash commands from `.claude/commands/*.md` (e.g., `/commit`, `/documentation`).
- **Rules:** Reads modular persistent rules from `.claude/rules/*.md`.
- **Skills:** Auto-discovers skills from `.claude/skills/`.
- **MCP:** Discovers project-scoped MCP servers from `.mcp.json` at the repository root.

### 7.4 GitHub Copilot Integration

- **Workspace Instructions:** Reads `.github/copilot-instructions.md` on every chat request.
- **Prompt Files:** VS Code Copilot Chat discovers reusable prompts in `.github/prompts/*.prompt.md` and exposes them in the chat input via `/`.
- **Path-Specific Instructions:** VS Code GitHub Copilot applies `.github/instructions/*.instructions.md` to matching workspaces and languages.
- **MCP Configuration:** Discovers MCP servers via `.vscode/mcp.json` using the standard `"servers"` schema.

---

## 8\. Maintenance & Best Practices

1. **Always edit within** `.agents/`**:** Never edit files inside `.claude/`, `.github/prompts/`, or root symlinks directly; always modify the canonical target inside `.agents/`.
2. **Adding a new command:**
   - Create the command file in `.agents/commands/<command-name>.md`.
   - Add a symlink in `.claude/commands/<command-name>.md`.
   - Add a symlink in `.github/prompts/<command-name>.prompt.md`.
3. **Adding a new rule:**
   - Create the rule file in `.agents/rules/<rule-name>.md`.
   - Add a symlink in `.claude/rules/<rule-name>.md`.
   - Add a symlink in `.github/instructions/<rule-name>.instructions.md`.
4. **Validating symlink health:**
   - Run the following command to ensure no dangling or broken links exist:

     ```bash
     find . -xtype l
     ```
   - An empty output confirms that all symlinks resolve cleanly.