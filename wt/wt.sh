#!/usr/bin/env bash
set -euo pipefail

# wt — git worktree + Claude agent session manager
# Routes subcommands to individual scripts.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

usage() {
  cat <<EOF
Usage: wt <command> [args]

Commands:
  init <repo-url>        Clone repo as bare, create initial worktree + session
  new <branch> [base]    Create worktree + tmux session for a branch
  list                   List worktrees with session/agent status
  rm <branch>            Remove worktree, kill session, clean config
  agent [spawn|kill|list] Manage Claude agent panes
  promote                Promote current session to persistent sesh config
  help                   Show this help

Examples:
  wt init git@github.com:user/myapp.git
  wt new feature-auth
  wt agent spawn
  wt promote
  wt rm feature-auth
EOF
}

cmd="${1:-help}"
shift || true

case "$cmd" in
  init)    exec "$SCRIPT_DIR/wt-init.sh" "$@" ;;
  new)     exec "$SCRIPT_DIR/wt-new.sh" "$@" ;;
  list|ls) exec "$SCRIPT_DIR/wt-list.sh" "$@" ;;
  rm)      exec "$SCRIPT_DIR/wt-rm.sh" "$@" ;;
  agent)   exec "$SCRIPT_DIR/wt-agent.sh" "$@" ;;
  promote) exec "$SCRIPT_DIR/wt-promote.sh" "$@" ;;
  help|-h|--help) usage ;;
  *)
    echo "Unknown command: $cmd" >&2
    usage >&2
    exit 1
    ;;
esac
