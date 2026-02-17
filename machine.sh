#!/usr/bin/env bash
# Shared helper — resolves machine profile name and directory.
# Sourced by install.sh, switch-machine.sh, and build_sesh_config.sh.

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

MACHINE_FILE="$DOTFILES_DIR/.machine"
MACHINES_DIR="$DOTFILES_DIR/machines"

if [ -f "$MACHINE_FILE" ]; then
  MACHINE_NAME="$(grep -v '^#' "$MACHINE_FILE" | tr -d '[:space:]' | head -1)"
fi
MACHINE_NAME="${MACHINE_NAME:-default}"

MACHINE_DIR="$MACHINES_DIR/$MACHINE_NAME"

if [ ! -d "$MACHINE_DIR" ]; then
  echo "Warning: machine profile '$MACHINE_NAME' not found, falling back to default" >&2
  MACHINE_NAME="default"
  MACHINE_DIR="$MACHINES_DIR/default"
fi
