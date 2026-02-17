#!/bin/zsh
# install fzf
# install fd
# install bat

export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
export FZF_DEFAULT_OPTS="--tmux center"
export INV_CMD='file=$(fzf --preview="bat --color=always {}") && nvim $file'
alias inv=$INV_CMD
export FZF_CTRL_T_COMMAND=""

# run-inv-widget() {
function run-inv-widget {
  local selection
  selection=$(fzf --preview="bat --color=always {}" <"$TTY")
  if [ -n "$selection" ]; then
    nvim $selection
  fi
}

zle     -N   run-inv-widget
bindkey -M emacs '^T' run-inv-widget
bindkey -M vicmd '^T' run-inv-widget
bindkey -M viins '^T' run-inv-widget

source <(fzf --zsh)
