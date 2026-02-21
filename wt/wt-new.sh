#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/wt-helpers.sh"

usage() {
  echo "Usage: wt new <branch> [base-ref]" >&2
  echo "  Run from within any worktree of the project." >&2
  exit 1
}

[ $# -lt 1 ] && usage

branch="$(wt_ensure_prefix "$1")"
base="${2:-}"

bare_root="$(wt_find_bare_root)" || {
  echo "Error: not inside a git worktree or bare repo" >&2
  exit 1
}

project="$(wt_project_name "$bare_root")"
worktree_dir="$bare_root/$branch"

if [ -d "$worktree_dir" ]; then
  echo "Error: worktree '$worktree_dir' already exists" >&2
  exit 1
fi

# Create the worktree (with a new branch or tracking an existing one)
echo "Creating worktree '$branch'..."
if [ -n "$base" ]; then
  git -C "$bare_root" worktree add -b "$branch" "$worktree_dir" "$base"
else
  # Try to check out existing branch; if it doesn't exist, create it
  if git -C "$bare_root" show-ref --verify --quiet "refs/heads/$branch" 2>/dev/null || \
     git -C "$bare_root" show-ref --verify --quiet "refs/remotes/origin/$branch" 2>/dev/null; then
    git -C "$bare_root" worktree add "$worktree_dir" "$branch"
  else
    git -C "$bare_root" worktree add -b "$branch" "$worktree_dir"
  fi
fi

# Create tmux session
session_name="$(wt_session_name "$project" "$branch")"

echo "Creating session '$session_name'..."
tmux new-session -d -s "$session_name" -c "$worktree_dir"
tmux rename-window -t "=$session_name:0" "code"
# Split right pane (20%) for Claude agent
tmux split-window -t "=$session_name:code" -h -l '20%' -c "$worktree_dir" "$WT_AGENT_CMD"
# Select left pane and launch editor
tmux select-pane -t "=$session_name:code.0"
tmux send-keys -t "=$session_name:code.0" "nvim" Enter

# Switch to the new session
if [ -n "${TMUX:-}" ]; then
  tmux switch-client -t "=$session_name"
else
  tmux attach-session -t "=$session_name"
fi
