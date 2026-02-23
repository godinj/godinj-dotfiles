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
backup_item "$HOME/.config/alacritty"   "alacritty"
backup_item "$HOME/.env"                 "env"

# Firefox profile
ff_os="$(uname -s)"
case "$ff_os" in
  Darwin) ff_dir="$HOME/Library/Application Support/Firefox" ;;
  Linux)  ff_dir="$HOME/.mozilla/firefox" ;;
  *)      ff_dir="" ;;
esac

if [ -n "$ff_dir" ] && [ -f "$ff_dir/profiles.ini" ]; then
  backup_item "$ff_dir/profiles.ini" "firefox-profiles.ini"

  ff_profile_rel="$(awk '
    /^\[Install/ { in_install=1; next }
    /^\[/        { in_install=0 }
    in_install && /^Default=/ { sub(/^Default=/, ""); print; exit }
  ' "$ff_dir/profiles.ini")"

  if [ -z "$ff_profile_rel" ]; then
    ff_profile_rel="$(awk '
      /^\[Profile/ { in_profile=1; is_rel=0; path=""; next }
      /^\[/        { if (in_profile && is_rel && path != "") { print path; exit }; in_profile=0 }
      in_profile && /^IsRelative=1/ { is_rel=1 }
      in_profile && /^Path=/ { sub(/^Path=/, ""); path=$0 }
      END { if (in_profile && is_rel && path != "") print path }
    ' "$ff_dir/profiles.ini")"
  fi

  if [ -n "$ff_profile_rel" ] && [ -d "$ff_dir/$ff_profile_rel" ]; then
    backup_item "$ff_dir/$ff_profile_rel" "firefox-profile"
  fi
fi

echo ""
if [ "$backed_up" -gt 0 ]; then
  echo "Backup complete: $backed_up item(s) saved to $BACKUP_DIR"
else
  echo "Nothing to back up — no existing configs found."
  rmdir "$BACKUP_DIR" 2>/dev/null || true
fi
