#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/wt-helpers.sh"

usage() {
  cat <<EOF
Usage: wt agent [spawn|kill|list]

  spawn   Add a new Claude agent pane (creates "agents" window if needed)
  kill    Kill the last agent pane (or specify index)
  list    Show agent pane info

EOF
  exit 1
}

# Get current tmux session name
get_session() {
  tmux display-message -p '#{session_name}'
}

cmd="${1:-list}"
shift || true

session="$(get_session)"

case "$cmd" in
  spawn)
    # If "agents" window exists, split into it. Otherwise create it.
    if tmux list-windows -t "=$session" -F '#{window_name}' | grep -q '^agents$'; then
      tmux split-window -t "=$session:agents" -h -c "#{pane_current_path}" "$WT_AGENT_CMD"
      tmux select-layout -t "=$session:agents" even-horizontal
    else
      tmux new-window -t "=$session" -n "agents" -c "#{pane_current_path}" "$WT_AGENT_CMD"
    fi
    echo "Agent spawned."
    ;;

  kill)
    target="${1:-}"
    if tmux list-windows -t "=$session" -F '#{window_name}' | grep -q '^agents$'; then
      pane_count=$(tmux list-panes -t "=$session:agents" -F '#{pane_id}' | wc -l | tr -d ' ')
      if [ "$pane_count" -le 1 ]; then
        # Last pane — kill the whole window
        tmux kill-window -t "=$session:agents"
        echo "Agents window closed."
      else
        if [ -n "$target" ]; then
          tmux kill-pane -t "=$session:agents.$target"
        else
          # Kill last pane
          last_pane=$(tmux list-panes -t "=$session:agents" -F '#{pane_id}' | tail -1)
          tmux kill-pane -t "$last_pane"
        fi
        tmux select-layout -t "=$session:agents" even-horizontal
        echo "Agent killed."
      fi
    else
      echo "No agents window found. The first agent lives in the code window." >&2
    fi
    ;;

  list)
    echo "Session: $session"
    echo ""

    # Code window
    echo "Window: code"
    tmux list-panes -t "=$session:code" -F '  pane #{pane_index}: #{pane_current_command} (#{pane_width}x#{pane_height})' 2>/dev/null || \
      echo "  (no code window)"
    echo ""

    # Agents window
    if tmux list-windows -t "=$session" -F '#{window_name}' | grep -q '^agents$'; then
      echo "Window: agents"
      tmux list-panes -t "=$session:agents" -F '  pane #{pane_index}: #{pane_current_command} (#{pane_width}x#{pane_height})'
    else
      echo "Window: agents (none)"
    fi

    echo ""
    echo "Total agents: $(wt_count_agents "$session")"
    ;;

  *)
    usage
    ;;
esac
