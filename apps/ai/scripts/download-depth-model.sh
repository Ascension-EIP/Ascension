#!/usr/bin/env bash
# Downloads the metric depth model of the pathfinding (MoGe-2 ViT-S, ONNX, MIT):
# https://huggingface.co/Ruicheng/moge-2-vits-normal-onnx
# Public file, no token needed. Not versioned (134 MB): run from apps/ai, like download-model.sh.
set -euo pipefail

MODEL_FILE="resources/moge-2-vits-normal.onnx"
MODEL_URL="https://huggingface.co/Ruicheng/moge-2-vits-normal-onnx/resolve/main/model.onnx"
MODEL_SHA256="24eacb5dc7a2c54c7bc98f7de085ffbed79ad006ea5b664c2c2cdc02ff3a52f0"

if [ -f "$MODEL_FILE" ]; then
  echo "moge-2-vits-normal.onnx already present, skipping download."
  exit 0
fi

echo "Downloading moge-2-vits-normal.onnx (134 MB)..."
curl -fsSL -o "$MODEL_FILE.part" "$MODEL_URL"
echo "$MODEL_SHA256  $MODEL_FILE.part" | sha256sum -c --quiet - || {
  rm -f "$MODEL_FILE.part"
  echo "Checksum mismatch: the upstream file changed, check the model before updating MODEL_SHA256." >&2
  exit 1
}
mv "$MODEL_FILE.part" "$MODEL_FILE"
echo "Download complete."
