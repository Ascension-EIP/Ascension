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

CONFIG_FILE="${CONFIG_FILE:-config/production.json}"

echo "Building for platform: $PLATFORM with config: $CONFIG_FILE"

if [ "$PLATFORM" = "ios" ]; then
  flutter build ios --no-codesign --dart-define-from-file="$CONFIG_FILE"
else
  flutter build apk --dart-define-from-file="$CONFIG_FILE"
fi
