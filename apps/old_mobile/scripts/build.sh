#!/usr/bin/env bash
set -euo pipefail

PLATFORM="${BUILD_PLATFORM:-}"

if [ -z "$PLATFORM" ]; then
  if [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="ios"
  else
    PLATFORM="android"
  fi
fi

echo "Building for platform: $PLATFORM"

if [ "$PLATFORM" = "ios" ]; then
  flutter build ios --no-codesign "--dart-define=BACKEND_URL=${BACKEND_URL:-}"
else
  flutter build apk "--dart-define=BACKEND_URL=${BACKEND_URL:-}"
fi
