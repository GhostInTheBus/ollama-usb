#!/bin/bash
# setup.sh — copies the Ollama binary and your chosen models to this USB drive
# Run this once from the USB drive before using launch.command

set -e

DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==============================="
echo "  Ollama USB Setup"
echo "==============================="
echo "Installing to: $DIR"
echo ""

# --- Verify Ollama.app is installed ---
OLLAMA_BIN="/Applications/Ollama.app/Contents/Resources/ollama"
if [ ! -f "$OLLAMA_BIN" ]; then
  echo "ERROR: Ollama.app not found at $OLLAMA_BIN"
  echo "Download and install Ollama from https://ollama.com before running setup."
  exit 1
fi

# --- Copy the ollama binary ---
echo "Copying Ollama binary..."
cp "$OLLAMA_BIN" "$DIR/ollama"
chmod +x "$DIR/ollama"
xattr -d com.apple.quarantine "$DIR/ollama" 2>/dev/null
echo "Done."
echo ""

# --- List available local models ---
echo "Fetching locally installed models..."
MODELS=$(OLLAMA_MODELS=~/.ollama/models "$DIR/ollama" list 2>/dev/null | tail -n +2 | awk '{print $1}' | grep -v '^$')

if [ -z "$MODELS" ]; then
  echo "No local models found. Pull some models first with: ollama pull <model>"
  exit 1
fi

echo ""
echo "Available models:"
i=1
declare -a MODEL_ARRAY
while IFS= read -r model; do
  echo "  $i) $model"
  MODEL_ARRAY[$i]="$model"
  ((i++))
done <<< "$MODELS"

echo ""
echo "Which models do you want to copy to the USB?"
echo "Enter numbers separated by spaces (e.g. 1 3), or 'all' for everything:"
read -r SELECTION

if [ "$SELECTION" = "all" ]; then
  SELECTED=("${MODEL_ARRAY[@]}")
else
  SELECTED=()
  for num in $SELECTION; do
    if [ -n "${MODEL_ARRAY[$num]}" ]; then
      SELECTED+=("${MODEL_ARRAY[$num]}")
    else
      echo "WARNING: No model at index $num, skipping."
    fi
  done
fi

if [ ${#SELECTED[@]} -eq 0 ]; then
  echo "No models selected. Exiting."
  exit 1
fi

echo ""
echo "Copying ${#SELECTED[@]} model(s) to USB..."
echo ""

mkdir -p "$DIR/models"

for model in "${SELECTED[@]}"; do
  echo "--- $model ---"

  # Parse model name and tag
  NAME="${model%%:*}"
  TAG="${model##*:}"
  [ "$TAG" = "$NAME" ] && TAG="latest"

  MANIFEST_SRC="$HOME/.ollama/models/manifests/registry.ollama.ai/library/$NAME/$TAG"
  MANIFEST_DST="$DIR/models/manifests/registry.ollama.ai/library/$NAME"

  if [ ! -f "$MANIFEST_SRC" ]; then
    echo "  WARNING: Manifest not found for $model, skipping."
    continue
  fi

  # Copy manifest
  mkdir -p "$MANIFEST_DST"
  cp "$MANIFEST_SRC" "$MANIFEST_DST/$TAG"

  # Copy blobs referenced in manifest
  mkdir -p "$DIR/models/blobs"
  DIGESTS=$(grep -o '"sha256:[a-f0-9]*"' "$MANIFEST_SRC" | tr -d '"')
  for digest in $DIGESTS; do
    fname="${digest/:/-}"
    src="$HOME/.ollama/models/blobs/$fname"
    dst="$DIR/models/blobs/$fname"
    if [ -f "$dst" ]; then
      echo "  skipping $fname (already on USB)"
    elif [ -f "$src" ]; then
      SIZE=$(du -sh "$src" 2>/dev/null | cut -f1)
      echo "  copying $fname ($SIZE)..."
      cp "$src" "$dst"
    else
      echo "  WARNING: blob $fname not found locally, skipping."
    fi
  done

  echo "  $model done."
  echo ""
done

echo "==============================="
echo "  Setup complete!"
echo "==============================="
echo ""
echo "To start: double-click launch.command"
echo ""
