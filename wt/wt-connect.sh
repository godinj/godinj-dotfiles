#!/usr/bin/env bash
# Startup script for promoted worktree sessions.
# Used as startup_command in sesh TOML entries.
# Recreates the editor + agent layout in the current pane.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/wt-helpers.sh"

wt_setup_panes "" "$(pwd)" connect
