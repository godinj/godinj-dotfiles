#!/usr/bin/env bash
export PATH="$HOME/go/bin:$HOME/.local/bin:/usr/local/bin:$PATH"

# Resolve dotfiles dir and source machine-specific picker overrides
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$DOTFILES_DIR/machine.sh"

PICKER_CONF="$MACHINE_DIR/sesh/picker.sh"
if [ -f "$PICKER_CONF" ]; then
  source "$PICKER_CONF"
fi

SESH_BORDER_LABEL="${SESH_BORDER_LABEL:- sesh }"
SESH_PROMPT="${SESH_PROMPT:-⚡  }"
SESH_POPUP_SIZE="${SESH_POPUP_SIZE:-80%,70%}"
SESH_PREVIEW_WINDOW="${SESH_PREVIEW_WINDOW:-right:75%}"
SESH_COLOR="${SESH_COLOR:-}"

COLOR_FLAG=""
if [ -n "$SESH_COLOR" ]; then
  COLOR_FLAG="--color=$SESH_COLOR"
fi

TREE_LIST="$DOTFILES_DIR/sesh/sesh_tree_list.sh"

SELECTED="$(
  sesh list -t -c -z --icons | "$TREE_LIST" | fzf \
    --tmux "center,$SESH_POPUP_SIZE" \
    --no-sort --ansi --border-label "$SESH_BORDER_LABEL" --prompt "$SESH_PROMPT" \
    --delimiter='\t' --with-nth=2 --accept-nth=1 \
    $COLOR_FLAG \
    --header '  ^a all ^t tmux ^g configs ^x zoxide ^w worktrees ^d tmux kill ^f find' \
    --bind 'tab:down,btab:up' \
    --bind "ctrl-a:change-prompt($SESH_PROMPT)+reload(sesh list -t -c -z --icons | $TREE_LIST)" \
    --bind "ctrl-t:change-prompt(🪟  )+reload(sesh list -t --icons | $TREE_LIST)" \
    --bind "ctrl-g:change-prompt(⚙️  )+reload(sesh list -c --icons | $TREE_LIST)" \
    --bind "ctrl-x:change-prompt(📁  )+reload(sesh list -z --icons | $TREE_LIST)" \
    --bind "ctrl-w:change-prompt(  )+reload(sesh list -t --icons | grep ' ' | $TREE_LIST)" \
    --bind "ctrl-f:change-prompt(🔎  )+reload(fd -H -d 2 -t d -E .Trash . ~ | $TREE_LIST)" \
    --bind "ctrl-d:execute(bash -c 'tmux kill-session -t \"\${1#* }\"' _ {1})+change-prompt($SESH_PROMPT)+reload(sesh list --icons | $TREE_LIST)" \
    --preview-window "$SESH_PREVIEW_WINDOW" \
    --preview 'sesh preview {1}'
)"

[ -z "$SELECTED" ] && exit 0

# Create the directory if the selection looks like a path and doesn't exist
DIR="${SELECTED/#\~/$HOME}"
if [[ "$DIR" == /* ]] && [ ! -d "$DIR" ]; then
  mkdir -p "$DIR"
fi

sesh connect "$SELECTED"
