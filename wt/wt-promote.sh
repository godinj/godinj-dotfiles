#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/wt-helpers.sh"

# Must be run from inside a worktree or bare repo
bare_root="$(wt_find_bare_root)" || {
  echo "Error: not inside a git worktree or bare repo" >&2
  exit 1
}

project="$(wt_project_name "$bare_root")"
default_branch="$(git -C "$bare_root" symbolic-ref --short HEAD 2>/dev/null || echo main)"

if [ $# -ge 1 ]; then
  # Argument given: resolve branch and worktree path
  branch="$(wt_ensure_prefix "$1")"
  wt_path="$bare_root/$branch"
  if [ ! -d "$wt_path" ]; then
    echo "Error: worktree not found at $wt_path" >&2
    exit 1
  fi
else
  # No argument: use current directory
  wt_path="$(pwd)"
  branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
fi

# Determine session and bare names
if [ "$branch" = "$default_branch" ]; then
  session_name="$(wt_session_name "$project")"
  bare_name="$(wt_bare_name "$project")"
else
  session_name="$(wt_session_name "$project" "$branch")"
  bare_name="$(wt_bare_name "$project" "$branch")"
fi

# Check if already promoted
if [ -f "$WT_WORKTREES_TOML" ] && grep -q "name = \"$bare_name\"" "$WT_WORKTREES_TOML" 2>/dev/null; then
  echo "Session '$session_name' is already promoted." >&2
  exit 1
fi

# Shorten path for TOML (use ~ for home)
toml_path="${wt_path/#$HOME/~}/"
# Ensure single trailing slash
toml_path="${toml_path%%/}/"

# Append to worktrees.toml
{
  if [ -s "$WT_WORKTREES_TOML" ]; then
    printf '\n'
  fi
  cat <<EOF
[[session]]
name = "$bare_name"
path = "$toml_path"
startup_command = "$WT_DOTFILES_DIR/wt/wt-connect.sh"
EOF
} >> "$WT_WORKTREES_TOML"

echo "Promoted '$session_name' to worktrees.toml"

# Rebuild sesh config
"$WT_DOTFILES_DIR/sesh/build_sesh_config.sh"
echo "Sesh config rebuilt."
