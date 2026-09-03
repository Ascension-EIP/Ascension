---
name: graphify
description: Turn any folder of files into a navigable knowledge graph and query architecture using graphify-out/
---

# Skill: graphify

Turn any folder of files into a navigable knowledge graph and query codebase architecture.

## Instructions

1. If a graph exists at `graphify-out/graph.json`, prefer querying it using `graphify query "<question>"` or MCP tools.
2. To update the knowledge graph after code changes, execute:
   ```bash
   graphify update .
   ```
3. To view graph summary, inspect `graphify-out/GRAPH_REPORT.md`.
