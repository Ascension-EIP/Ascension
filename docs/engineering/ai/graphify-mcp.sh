#!/usr/bin/env bash
# Portable wrapper to launch the Graphify MCP Server
# Works on any machine that clones this repository

# Get absolute path of graph.json
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
GRAPH_JSON="$REPO_ROOT/graphify-out/graph.json"

# Make sure graphify-out directory exists
mkdir -p "$REPO_ROOT/graphify-out"

# Check if graph.json exists
if [ ! -f "$GRAPH_JSON" ]; then
  # Create an empty graph JSON so the MCP server doesn't crash on start
  echo '{"nodes": [], "edges": [], "hyperedges": []}' > "$GRAPH_JSON"
fi

# 1. Try to locate the Python interpreter from the graphify binary shebang
if command -v graphify >/dev/null 2>&1; then
  GRAPHIFY_BIN=$(which graphify)
  PYTHON_BIN=$(head -n 1 "$GRAPHIFY_BIN" | tr -d '#!')
  if [ -x "$PYTHON_BIN" ] && "$PYTHON_BIN" -c "import graphify.serve" >/dev/null 2>&1; then
    exec "$PYTHON_BIN" -m graphify.serve "$GRAPH_JSON"
  fi
fi

# 2. Try running via uv tool run
if command -v uv >/dev/null 2>&1; then
  exec uv tool run graphifyy python -m graphify.serve "$GRAPH_JSON"
fi

# 3. Fallback to global python3 if it has graphify installed
if python3 -c "import graphify.serve" >/dev/null 2>&1; then
  exec python3 -m graphify.serve "$GRAPH_JSON"
fi

echo "Error: Graphify is not installed and uv is not available." >&2
exit 1
