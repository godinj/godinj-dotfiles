#!/usr/bin/env bash
set -euo pipefail

# Merges sesh/base.toml + sesh/sessions/*.toml into ~/.config/sesh/sesh.toml

SESH_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR="${HOME}/.config/sesh"
OUTPUT_FILE="${OUTPUT_DIR}/sesh.toml"

mkdir -p "$OUTPUT_DIR"

{
  cat "$SESH_DIR/base.toml"
  for f in "$SESH_DIR"/sessions/*.toml; do
    printf '\n'
    cat "$f"
  done
} > "$OUTPUT_FILE"
