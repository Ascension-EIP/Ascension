#!/usr/bin/env bash
set -eo pipefail

CONFIG_FILE="${CONFIG_FILE:-config/development.json}"
EXTRA_ARGS=()

for arg in "$@"; do
  case "$arg" in
    --prod|--production)
      CONFIG_FILE="config/production.json"
      ;;
    *)
      EXTRA_ARGS+=("$arg")
      ;;
  esac
done

# Reverse ports if an Android device is connected via ADB and using local development
if [[ "$CONFIG_FILE" == *"development"* ]] && command -v adb >/dev/null 2>&1; then
  if adb devices 2>/dev/null | grep -E -q "[a-zA-Z0-9]+\s+device$"; then
    echo "==> Android device detected via ADB: forwarding ports..."
    adb reverse tcp:8080 tcp:8080 2>/dev/null && echo "  ✔ Port 8080 forwarded (Backend API)" || true
    adb reverse tcp:9000 tcp:9000 2>/dev/null && echo "  ✔ Port 9000 forwarded (RustFS / S3)" || true
  fi
fi

echo "==> Running mobile app with config: $CONFIG_FILE"

exec flutter run --dart-define-from-file="$CONFIG_FILE" ${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"}
