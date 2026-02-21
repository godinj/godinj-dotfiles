#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/wt-helpers.sh"

bare_root="$(wt_find_bare_root)" || {
  echo "Error: not inside a git worktree or bare repo" >&2
  exit 1
}

project="$(wt_project_name "$bare_root")"

# Parse porcelain output
printf "%-20s %-12s %-8s %s\n" "BRANCH" "SESSION" "AGENTS" "PATH"
printf "%-20s %-12s %-8s %s\n" "------" "-------" "------" "----"

git -C "$bare_root" worktree list --porcelain | while read -r line; do
  case "$line" in
    "worktree "*)
      wt_path="${line#worktree }"
      ;;
    "branch "*)
      ref="${line#branch }"
      branch="${ref##refs/heads/}"
      ;;
    "HEAD "*)
      # detached HEAD — use abbreviated commit
      branch="(detached)"
      ;;
    "bare")
      # The bare repo itself, skip
      wt_path=""
      branch=""
      ;;
    "")
      # End of record — print if we have a path
      if [ -n "${wt_path:-}" ] && [ -n "${branch:-}" ]; then
        # Determine session name
        default_branch="$(git -C "$bare_root" symbolic-ref --short HEAD 2>/dev/null || echo main)"
        if [ "$branch" = "$default_branch" ]; then
          session_name="$(wt_session_name "$project")"
        else
          session_name="$(wt_session_name "$project" "$branch")"
        fi

        # Check tmux session status
        if wt_session_exists "$session_name"; then
          session_status="active"
          agents="$(wt_count_agents "$session_name")"
        else
          session_status="-"
          agents="-"
        fi

        # Shorten home directory in path
        display_path="${wt_path/#$HOME/~}"

        printf "%-20s %-12s %-8s %s\n" "$branch" "$session_status" "$agents" "$display_path"
      fi
      wt_path=""
      branch=""
      ;;
  esac
done
