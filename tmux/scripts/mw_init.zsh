#!/bin/zsh

export MW_SESSION_NAME=" MW"
export C="tmux send-keys -t $MW_SESSION_NAME.0 'km' ENTER && tmux a -t $MW_SESSION_NAME"
tmux send-keys -t $MW_SESSION_NAME.0 "read -k '?Enable Cisco, then press any key...' && km && dd -t '$C'" ENTER
