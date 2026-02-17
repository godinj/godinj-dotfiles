#!/bin/zsh

cmd="eval \"$*\""

sess=$(tmux display-message -p '#S')
n_pane=$(tmux list-panes | wc -l)

for ((i = 0; i < $n_pane; i++)); do 
  pane="$sess.$i";
  tmux send-keys -t $pane $cmd Enter
done
