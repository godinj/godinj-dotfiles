#!/usr/bin/env bash
# Startup script for promoted worktree sessions.
# Used as startup_command in sesh TOML entries.
# Recreates the editor + agent layout in the current pane.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/wt-helpers.sh"

# Split right pane (20%) for Claude agent
tmux split-window -h -l '20%' "$WT_AGENT_CMD"

# Select left pane and exec nvim (replaces this script's shell)
tmux select-pane -L
exec nvim
