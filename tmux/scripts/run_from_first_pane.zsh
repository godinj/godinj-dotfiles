#!/bin/zsh

cmd="$1"
args="$2"
combined="$cmd \"$args\""

sess=$(tmux display-message -p '#S')
o_pane=$(tmux display-message -p '#{pane_index}')

re_sel="tmux select-pane -t $o_pane"

tmux send-keys -t "$sess.0" "$n_cmd; $re_sel" Enter
