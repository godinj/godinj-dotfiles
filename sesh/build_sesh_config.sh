#!/usr/bin/env bash
set -euo pipefail

# Merges sesh/base.toml + shared sessions + machine sessions + local sessions
# into ~/.config/sesh/sesh.toml

SESH_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_DIR="$(cd "$SESH_DIR/.." && pwd)"
OUTPUT_DIR="${HOME}/.config/sesh"
OUTPUT_FILE="${OUTPUT_DIR}/sesh.toml"

# Resolve machine profile
source "$DOTFILES_DIR/machine.sh"

mkdir -p "$OUTPUT_DIR"

{
  # 1. Base config
  cat "$SESH_DIR/base.toml"

  # 2. Shared sessions (skip local.toml)
  for f in "$SESH_DIR"/sessions/*.toml; do
    [ -f "$f" ] || continue
    [ "$(basename "$f")" = "local.toml" ] && continue
    printf '\n'
    cat "$f"
  done

  # 2.5. Worktree sessions (promoted worktrees)
  if [ -f "$MACHINE_DIR/sesh/sessions/worktrees.toml" ]; then
    printf '\n'
    cat "$MACHINE_DIR/sesh/sessions/worktrees.toml"
  fi

  # 3. Machine-specific sessions (skip worktrees.toml, already included above)
  if [ -d "$MACHINE_DIR/sesh/sessions" ]; then
    for f in "$MACHINE_DIR"/sesh/sessions/*.toml; do
      [ -f "$f" ] || continue
      [ "$(basename "$f")" = "worktrees.toml" ] && continue
      printf '\n'
      cat "$f"
    done
  fi

  # 4. Local overrides (gitignored)
  if [ -f "$SESH_DIR/sessions/local.toml" ]; then
    printf '\n'
    cat "$SESH_DIR/sessions/local.toml"
  fi
} > "$OUTPUT_FILE"
