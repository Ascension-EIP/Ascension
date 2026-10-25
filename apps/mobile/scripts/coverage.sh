#!/usr/bin/env bash
# ==============================================================================
# Ascension Mobile - Coverage Generation Script
# Runs flutter tests with coverage, filters generated files, and builds HTML report.
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${APP_DIR}"

FLUTTER_BIN="flutter"
if [ -x "/opt/flutter/bin/flutter" ]; then
  FLUTTER_BIN="/opt/flutter/bin/flutter"
fi

echo "🧪 Running tests with coverage and expanded reporter..."
"$FLUTTER_BIN" test --coverage --reporter expanded "$@"

if [ ! -f "coverage/lcov.info" ]; then
  echo "❌ Error: coverage/lcov.info was not generated."
  exit 1
fi

# Filter out generated files (*.g.dart, *.freezed.dart) if lcov is available
if command -v lcov &> /dev/null; then
  echo "🧹 Filtering out generated files (*.g.dart, *.freezed.dart)..."
  lcov --ignore-errors empty,unused --remove coverage/lcov.info \
    'lib/**/*.g.dart' \
    'lib/**/*.freezed.dart' \
    'lib/core/l10n/translations/*.dart' \
    -o coverage/lcov.cleaned.info --quiet || cp coverage/lcov.info coverage/lcov.cleaned.info
else
  cp coverage/lcov.info coverage/lcov.cleaned.info
fi

# Generate HTML report if genhtml is available
if command -v genhtml &> /dev/null; then
  echo "📊 Generating HTML coverage report..."
  genhtml --ignore-errors empty,unused,corrupt -o coverage/html \
    --legend \
    --title "Ascension Mobile - Code Coverage" \
    coverage/lcov.cleaned.info --quiet

  echo "✅ HTML coverage report generated at: ${APP_DIR}/coverage/html/index.html"
  
  if [[ "$*" == *"--open"* ]]; then
    if command -v xdg-open &> /dev/null; then
      xdg-open "${APP_DIR}/coverage/html/index.html"
    elif command -v open &> /dev/null; then
      open "${APP_DIR}/coverage/html/index.html"
    fi
  fi
else
  echo "⚠️ Warning: 'genhtml' is not installed. HTML report skipped."
  echo "   Install 'lcov' package on your system to generate HTML reports."
fi
