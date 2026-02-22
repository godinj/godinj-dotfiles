#!/usr/bin/env bash
# Shared helpers for wt commands. Sourced, not executed.

WT_BRANCH_PREFIX="feature/"
WT_GIT_BASE="$HOME/git"
WT_DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source "$WT_DOTFILES_DIR/machine.sh"
source "$WT_DOTFILES_DIR/sesh/icons.sh"
WT_ICON="$ICON_WORKTREE"
WT_PROJECT_ICON="$ICON_WORKTREE_PROJECT"
WT_WORKTREES_TOML="$MACHINE_DIR/sesh/sessions/worktrees.toml"

# Add branch prefix if not already present.
wt_ensure_prefix() {
  local branch="$1"
  if [[ "$branch" == "$WT_BRANCH_PREFIX"* ]]; then
    echo "$branch"
  else
    echo "${WT_BRANCH_PREFIX}${branch}"
  fi
}

# Detect bare repo root from any worktree or bare repo directory.
# Returns the path to the bare repo (e.g. ~/git/project.git).
wt_find_bare_root() {
  local git_common_dir
  git_common_dir="$(git rev-parse --git-common-dir 2>/dev/null)" || return 1

  # If we're inside the bare repo itself, git-common-dir returns "."
  if [ "$git_common_dir" = "." ]; then
    pwd
    return 0
  fi

  # git-common-dir returns the path to the .git of the bare repo
  # For a bare repo, this IS the bare repo directory
  # Resolve to absolute path and strip trailing /worktrees/<name> if present
  local abs_path
  abs_path="$(cd "$git_common_dir" && pwd)"
  echo "$abs_path"
}

# Extract project name from bare repo path (foo.git -> foo).
wt_project_name() {
  local bare_root="${1:-$(wt_find_bare_root)}"
  basename "$bare_root" .git
}

# Generate session name:
#   "󰀜 project/feature/name"  for feature branches
#   "󰀜 project/branch"        for non-prefixed branches
#   "󱁤 project"               for default branch
wt_session_name() {
  local project="$1"
  local branch="${2:-}"
  if [ -n "$branch" ]; then
    echo "$WT_ICON $project/$branch"
  else
    echo "$WT_PROJECT_ICON $project"
  fi
}

# Return bare session name (no icon prefix).
#   "project/feature/name"  for feature branches
#   "project/branch"        for non-prefixed branches
#   "project"               for default branch
wt_bare_name() {
  local project="$1"
  local branch="${2:-}"
  if [ -n "$branch" ]; then
    echo "$project/$branch"
  else
    echo "$project"
  fi
}

# Check if a tmux session exists.
wt_session_exists() {
  tmux has-session -t "=$1" 2>/dev/null
}

# Count agent panes. Counts panes in the "code" window's right split
# plus all panes in an "agents" window if it exists.
wt_count_agents() {
  local session="$1"
  local count=0

  # Count panes in "agents" window
  if tmux list-windows -t "=$session" -F '#{window_name}' 2>/dev/null | grep -q '^agents$'; then
    local agents_panes
    agents_panes=$(tmux list-panes -t "=$session:agents" -F '#{pane_id}' 2>/dev/null | wc -l | tr -d ' ')
    count=$((count + agents_panes))
  fi

  # The code window has 2 panes if an agent is beside the editor
  local code_panes
  code_panes=$(tmux list-panes -t "=$session:code" -F '#{pane_id}' 2>/dev/null | wc -l | tr -d ' ')
  if [ "$code_panes" -ge 2 ]; then
    count=$((count + code_panes - 1))
  fi

  echo "$count"
}

# Get the default branch name for the bare repo.
wt_default_branch() {
  git symbolic-ref --short HEAD 2>/dev/null || echo "main"
}

# Set up panes for a worktree session's code window.
# Usage: wt_setup_panes <session> <workdir> [new|connect]
#   new     — session already exists detached; target panes by session name
#   connect — running inside the current pane (sesh startup_command)
wt_setup_panes() {
  local session="$1"
  local workdir="$2"
  local mode="${3:-new}"

  # Collect WT_PANE_* specs
  local panes=()
  local i=0
  while true; do
    local var="WT_PANE_$i"
    local val="${!var:-}"
    [ -z "$val" ] && break
    panes+=("$val")
    ((i++))
  done

  # Default: nvim + agent
  if [ ${#panes[@]} -eq 0 ]; then
    panes=("nvim" "${WT_AGENT_CMD:-cld}:20%")
  fi

  local first_cmd="${panes[0]%%:*}"

  # Create additional panes right-to-left so they end up in order.
  # Always split from pane 0; tmux sizes are window percentages.
  for ((i=${#panes[@]}-1; i>=1; i--)); do
    local spec="${panes[$i]}"
    local cmd="${spec%%:*}"
    local size="${spec#*:}"
    [ "$size" = "$spec" ] && size="20%"

    if [ "$mode" = "new" ]; then
      tmux split-window -t "=$session:code.0" -h -l "$size" -c "$workdir" "$cmd"
    else
      tmux split-window -h -l "$size" "$cmd"
    fi
  done

  # Focus pane 0 and launch its command
  if [ "$mode" = "new" ]; then
    tmux select-pane -t "=$session:code.0"
    tmux send-keys -t "=$session:code.0" "$first_cmd" Enter
  else
    tmux select-pane -t :.0
    exec $first_cmd
  fi
}

# Project-level config: source .wt.env from the bare repo root.
_wt_saved_agent_cmd="${WT_AGENT_CMD:-}"
_wt_bare="$(wt_find_bare_root 2>/dev/null)" || true
if [ -n "$_wt_bare" ] && [ -f "$_wt_bare/.wt.env" ]; then
  source "$_wt_bare/.wt.env"
fi
# Env WT_AGENT_CMD beats .wt.env value
[ -n "$_wt_saved_agent_cmd" ] && WT_AGENT_CMD="$_wt_saved_agent_cmd"
# Default WT_AGENT_CMD: derive from WT_PANE_1, fall back to "cld"
if [ -z "${WT_AGENT_CMD:-}" ]; then
  _wt_pane1="${WT_PANE_1:-}"
  WT_AGENT_CMD="${_wt_pane1%%:*}"
  WT_AGENT_CMD="${WT_AGENT_CMD:-cld}"
  unset _wt_pane1
fi
unset _wt_saved_agent_cmd _wt_bare
