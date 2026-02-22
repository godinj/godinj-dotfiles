#!/usr/bin/env bash
set -euo pipefail

# Merges sesh/base.toml + shared sessions + machine sessions + local sessions
# into ~/.config/sesh/sesh.toml
# Icons are prepended to session names at build time from icons.sh.

SESH_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_DIR="$(cd "$SESH_DIR/.." && pwd)"
OUTPUT_DIR="${HOME}/.config/sesh"
OUTPUT_FILE="${OUTPUT_DIR}/sesh.toml"

# Resolve machine profile
source "$DOTFILES_DIR/machine.sh"

# Central icon definitions
source "$SESH_DIR/icons.sh"

# Map a session file basename to its icon.
icon_for_file() {
  case "$1" in
    tools.toml)      echo "$ICON_TOOL" ;;
    config.toml)     echo "$ICON_CONFIG" ;;
    worktrees.toml)  echo "WORKTREE" ;;   # sentinel; handled by prepend_worktree_icon
    *)               echo "$ICON_PROJECT" ;;
  esac
}

# Awk filter: prepend icon to each name = "..." value.
prepend_icon() {
  local file="$1"
  local icon="$2"
  awk -v icon="$icon" '
    /^name = "/ { sub(/^name = "/, "name = \"" icon " ") }
    { print }
  ' "$file"
}

# Awk filter for worktrees: choose icon based on whether the name contains "/".
# Names with "/" get ICON_WORKTREE; names without get ICON_WORKTREE_PROJECT.
prepend_worktree_icon() {
  local file="$1"
  awk -v wt_icon="$ICON_WORKTREE" -v proj_icon="$ICON_WORKTREE_PROJECT" '
    /^name = "/ {
      name = $0
      sub(/^name = "/, "", name)
      sub(/".*$/, "", name)
      if (index(name, "/") > 0) {
        sub(/^name = "/, "name = \"" wt_icon " ")
      } else {
        sub(/^name = "/, "name = \"" proj_icon " ")
      }
    }
    { print }
  ' "$file"
}

mkdir -p "$OUTPUT_DIR"

{
  # 1. Base config
  cat "$SESH_DIR/base.toml"

  # 2. Shared sessions (skip local.toml)
  for f in "$SESH_DIR"/sessions/*.toml; do
    [ -f "$f" ] || continue
    [ "$(basename "$f")" = "local.toml" ] && continue
    printf '\n'
    local_icon="$(icon_for_file "$(basename "$f")")"
    prepend_icon "$f" "$local_icon"
  done

  # 2.5. Worktree sessions (promoted worktrees)
  if [ -f "$MACHINE_DIR/sesh/sessions/worktrees.toml" ]; then
    printf '\n'
    prepend_worktree_icon "$MACHINE_DIR/sesh/sessions/worktrees.toml"
  fi

  # 3. Machine-specific sessions (skip worktrees.toml, already included above)
  if [ -d "$MACHINE_DIR/sesh/sessions" ]; then
    for f in "$MACHINE_DIR"/sesh/sessions/*.toml; do
      [ -f "$f" ] || continue
      [ "$(basename "$f")" = "worktrees.toml" ] && continue
      printf '\n'
      local_icon="$(icon_for_file "$(basename "$f")")"
      prepend_icon "$f" "$local_icon"
    done
  fi

  # 4. Local overrides (gitignored)
  if [ -f "$SESH_DIR/sessions/local.toml" ]; then
    printf '\n'
    local_icon="$(icon_for_file "local.toml")"
    prepend_icon "$SESH_DIR/sessions/local.toml" "$local_icon"
  fi
} > "$OUTPUT_FILE"
