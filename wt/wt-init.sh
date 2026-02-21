#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/wt-helpers.sh"

usage() {
  echo "Usage: wt init <repo-url>" >&2
  exit 1
}

[ $# -lt 1 ] && usage

repo_url="$1"

# Extract project name from URL (strip .git suffix, get last path component)
name="$(basename "$repo_url" .git)"
bare_dir="$WT_GIT_BASE/${name}.git"

if [ -d "$bare_dir" ]; then
  echo "Error: $bare_dir already exists" >&2
  exit 1
fi

echo "Cloning $repo_url as bare repo..."
git clone --bare "$repo_url" "$bare_dir"

# Fix remote.origin.fetch — bare repos don't set this by default,
# which prevents `git fetch` from updating remote tracking branches.
git -C "$bare_dir" config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'

# Determine default branch
cd "$bare_dir"
default_branch="$(wt_default_branch)"
worktree_dir="$bare_dir/$default_branch"

echo "Creating worktree for '$default_branch'..."
git worktree add "$worktree_dir" "$default_branch"

# Create tmux session with editor + agent layout
session_name="$(wt_session_name "$name")"

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
