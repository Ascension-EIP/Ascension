#!/usr/bin/env bash
set -eo pipefail

# Reverse ports if an Android device is connected via ADB
if command -v adb >/dev/null 2>&1; then
  if adb devices 2>/dev/null | grep -E -q "[a-zA-Z0-9]+\s+device$"; then
    echo "==> Android device detected via ADB: forwarding ports..."
    adb reverse tcp:8080 tcp:8080 2>/dev/null && echo "  ✔ Port 8080 forwarded (Backend API)" || true
    adb reverse tcp:9000 tcp:9000 2>/dev/null && echo "  ✔ Port 9000 forwarded (RustFS / S3)" || true
  fi
fi

exec flutter run "--dart-define=BACKEND_URL=${BACKEND_URL:-http://localhost:8080}" "$@"
