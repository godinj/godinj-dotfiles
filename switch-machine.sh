#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

info()  { printf "\033[1;34m::\033[0m %s\n" "$*"; }
ok()    { printf "\033[1;32m✓\033[0m  %s\n" "$*"; }
err()   { printf "\033[1;31m✗\033[0m  %s\n" "$*"; }

source "$DOTFILES_DIR/machine.sh"

# ── Select profile ────────────────────────────────────────────────────────

profiles=()
for d in "$MACHINES_DIR"/*/; do
  [ -d "$d" ] || continue
  profiles+=("$(basename "$d")")
done

if [ "${1:-}" != "" ]; then
  MACHINE_NAME="$1"
  found=false
  for p in "${profiles[@]}"; do
    [ "$p" = "$MACHINE_NAME" ] && found=true
  done
  if [ "$found" = false ]; then
    err "Unknown profile: $MACHINE_NAME"
    echo "Available: ${profiles[*]}"
    exit 1
  fi
else
  info "Available machine profiles:"
  for i in "${!profiles[@]}"; do
    marker=""
    [ "${profiles[$i]}" = "$MACHINE_NAME" ] && marker=" (current)"
    echo "  $((i+1))) ${profiles[$i]}${marker}"
  done
  while true; do
    read -rp "Select profile [1-${#profiles[@]}]: " choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#profiles[@]}" ]; then
      MACHINE_NAME="${profiles[$((choice-1))]}"
      break
    fi
    echo "  Invalid choice, try again."
  done
fi

# ── Apply profile ─────────────────────────────────────────────────────────

echo "$MACHINE_NAME" > "$MACHINE_FILE"
MACHINE_DIR="$MACHINES_DIR/$MACHINE_NAME"
ok "Machine profile set to: $MACHINE_NAME"

cp "$MACHINE_DIR/tmux/machine.conf" "$DOTFILES_DIR/tmux/machine.conf"
ok "Copied tmux/machine.conf"

cp "$MACHINE_DIR/nvim/theme.lua" "$DOTFILES_DIR/nvim/lua/custom/plugins/machine_theme.lua"
ok "Copied nvim machine_theme.lua"

bash "$DOTFILES_DIR/sesh/build_sesh_config.sh"
ok "Rebuilt sesh.toml"

info "Done! Reload tmux (prefix + r) and restart nvim to pick up changes."
