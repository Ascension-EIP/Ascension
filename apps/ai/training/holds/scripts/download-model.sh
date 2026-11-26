#!/usr/bin/env bash
set -euo pipefail

BASE_URL="https://github.com/ultralytics/assets/releases/download/v8.4.0"
MODELS=("yolo26n-seg.pt" "yolo26s-seg.pt")

mkdir -p models
for model in "${MODELS[@]}"; do
  if [ -f "models/$model" ]; then
    echo "$model already present, skipping download."
    continue
  fi
  echo "Downloading $model..."
  curl -fsSL -o "models/$model" "$BASE_URL/$model"
done
echo "Download complete."
