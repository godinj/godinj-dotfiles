#!/usr/bin/env bash
set -euo pipefail

BACKUP_ROOT="$HOME/.dotfiles-backup"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"

mkdir -p "$BACKUP_DIR"

backed_up=0

backup_item() {
  local target="$1"
  local label="$2"

  if [ -e "$target" ] || [ -L "$target" ]; then
    # Record symlink info if applicable
    if [ -L "$target" ]; then
      echo "$label -> $(readlink "$target")" >> "$BACKUP_DIR/symlink-info.txt"
    fi

    cp -RL "$target" "$BACKUP_DIR/$label" 2>/dev/null || cp -R "$target" "$BACKUP_DIR/$label" 2>/dev/null || true
    echo "  Backed up: $target"
    backed_up=$((backed_up + 1))
  fi
}

echo "Backing up existing configs to $BACKUP_DIR ..."
echo ""

backup_item "$HOME/.zshrc"               "zshrc"
backup_item "$HOME/.gitconfig"           "gitconfig"
backup_item "$HOME/.config/nvim"         "nvim"
backup_item "$HOME/tmux-config"          "tmux-config"
backup_item "$HOME/.tmux.conf"           "tmux.conf"
backup_item "$HOME/.config/sesh/sesh.toml" "sesh.toml"
backup_item "$HOME/.env"                 "env"

echo ""
if [ "$backed_up" -gt 0 ]; then
  echo "Backup complete: $backed_up item(s) saved to $BACKUP_DIR"
else
  echo "Nothing to back up — no existing configs found."
  rmdir "$BACKUP_DIR" 2>/dev/null || true
fi
