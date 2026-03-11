#!/usr/bin/env bash
set -euo pipefail

MODEL_FILE="pose_landmarker.task"
MODEL_URL="https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_heavy/float16/latest/pose_landmarker_heavy.task"

if [ -f "$MODEL_FILE" ]; then
  echo "pose_landmarker.task already present, skipping download."
  exit 0
fi

echo "Downloading pose_landmarker.task model..."
curl -fsSL -o "$MODEL_FILE" "$MODEL_URL"
echo "Download complete."
