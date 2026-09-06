---
name: graphify
description: "AI Command: Consult and update the Graphify Knowledge Graph (/graphify)"
globs: ["*"]
alwaysApply: false
---

> **Last updated:** 3rd September 2026  
> **Version:** 1.0  
> **Authors:** Nicolas TORO  
> **Original language:** French  
> **Status:** Done  
> {.is-success}

---

# AI Command: Knowledge Graph (`/graphify`)

This document serves as a guide and execution protocol for any AI model (Antigravity, Copilot, Claude Code) performing architectural analysis or codebase research via **Graphify**.

---

## Table of Contents

- [AI Command: Knowledge Graph (`/graphify`)](#ai-command-knowledge-graph-graphify)
  - [Table of Contents](#table-of-contents)
  - [1. Command Objective](#1-command-objective)
  - [2. Graph Query Protocols](#2-graph-query-protocols)
  - [3. Automatic Update (Post-Modifications)](#3-automatic-update-post-modifications)
  - [4. Setup and Reset](#4-setup-and-reset)

---

## 1. Command Objective

Allows the AI to analyze the monorepo architecture by querying the pre-generated knowledge graph in `graphify-out/`. This reduces hallucinations and replaces heavy global searches with targeted, token-efficient subgraphs.

---

## 2. Graph Query Protocols

When `graphify-out/graph.json` exists, the AI must prioritize querying the graph using the most appropriate method:

1. **Architecture or Codebase Question:**
   Run `graphify query "<question>"` CLI command or use the MCP tool `query_graph`.
2. **Search for relationships and dependencies between two components:**
   Run `graphify path "<ComponentA>" "<ComponentB>"` or `shortest_path`.
3. **Focused analysis of a concept or module:**
   Run `graphify explain "<concept>"` or `get_node`.
4. **Navigation via generated documentation:**
   If `graphify-out/wiki/index.md` exists, prefer reading it over raw source browsing.
5. **Global Architecture Review:**
   Consult `graphify-out/GRAPH_REPORT.md` only for a broad overview or if targeted queries do not surface enough context.

---

## 3. Automatic Update (Post-Modifications)

After modifying code or documentation files during a session, the AI must keep the graph synchronized by executing the following command at the repository root:

```bash
graphify update .
```

*Note: This update is strictly AST-based (zero LLM API cost).*

---

## 4. Setup and Reset

If the graph needs to be rebuilt or reset, execute the moon task:

```bash
moon run :graphify-setup
```
