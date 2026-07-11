
# Kiro CLI pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh"

# Dotfiles directory detection
export DOTFILES_DIR="$(cd "$(dirname "$(readlink -f ~/.zshrc)" 2>/dev/null || readlink ~/.zshrc)" && cd .. && pwd)"

# Source secrets from .env (gitignored)
[ -f ~/.env ] && source ~/.env

# Central icon definitions for sesh sessions
source "$DOTFILES_DIR/sesh/icons.sh"

# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:$HOME/.local/bin:$HOME/go/bin:/usr/local/bin:$PATH
export PATH=/opt/homebrew/bin:$PATH
export PATH=/opt/local/bin:$PATH
export PATH=/usr/local/lib:$PATH
export PATH="$HOME/tmux-config/scripts:$PATH"
export PATH="$DOTFILES_DIR/sesh:$PATH"
export PATH="$DOTFILES_DIR/wt:$PATH"
export PATH="$PATH:/Users/jggodin/Library/Python/3.9/bin"

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# To swap themes, change the value below and run: source ~/.zshrc
ZSH_THEME="rkj-repos"
export TERM="xterm-256color"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

source $ZSH/oh-my-zsh.sh

# Machine-specific overrides (prompt colors, aliases) — must be after oh-my-zsh
[ -f "$DOTFILES_DIR/zsh/machine.zsh" ] && source "$DOTFILES_DIR/zsh/machine.zsh"

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"


# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.

# alias v="nvim"
# alias vim="nvim"
_machine_ssh() {
  local host="$1"
  shift

  local -a base_opts call_opts remote_cmd
  [[ -n "${MACHINE_SSH_KEY:-}" ]] && base_opts+=(-i "$MACHINE_SSH_KEY")
  [[ -n "${MACHINE_DD_PORT:-}" ]] && base_opts+=(-p "$MACHINE_DD_PORT")
  [[ -n "${MACHINE_DD_OPTS:-}" ]] && base_opts+=(${(z)MACHINE_DD_OPTS})

  while (( $# )); do
    case "$1" in
      --)
        shift
        break
        ;;
      -[46AaCfGgKkMNnqsTtVvXxYy])
        call_opts+=("$1")
        shift
        ;;
      -[bcDEeFIiJLlmOopQRSWw])
        call_opts+=("$1")
        shift
        if (( $# == 0 )); then
          print -u2 "ssh option requires an argument: ${call_opts[-1]}"
          return 2
        fi
        call_opts+=("$1")
        shift
        ;;
      -[bcDEeFIiJLlmOopQRSWw]*|-*)
        call_opts+=("$1")
        shift
        ;;
      *)
        break
        ;;
    esac
  done

  remote_cmd=("$@")
  ssh "${base_opts[@]}" "${call_opts[@]}" "${MACHINE_DD_USER:-godinj}@$host" "${remote_cmd[@]}"
}

dd() { _machine_ssh "${MACHINE_DD_HOST:-script.dremhome.org}" "$@"; }
bd() { _machine_ssh "${MACHINE_BD_HOST:-script.dremhome.org}" "$@"; }

# scp the most recent screenshot to a host (screenshot dir defaults to ~/Documents/screenshots)
_shot_scp() {
  local shot
  shot=$(ls -t "${SCREENSHOT_DIR:-$HOME/Documents/screenshots}"/Screenshot* 2>/dev/null | head -1)
  [[ -z "$shot" ]] && { echo "no screenshot found" >&2; return 1; }
  local opts=()
  [[ -n "$MACHINE_SSH_KEY" ]] && opts+=(-i "$MACHINE_SSH_KEY")
  [[ -n "$MACHINE_DD_PORT" ]] && opts+=(-P "$MACHINE_DD_PORT")
  scp "${opts[@]}" "$shot" "${MACHINE_DD_USER:-godinj}@$1:"
}
ddshot() { _shot_scp "${MACHINE_DD_HOST:-script.dremhome.org}"; }
bdshot() { _shot_scp "${MACHINE_BD_HOST:-script.dremhome.org}"; }
alias cl="claude"
alias kl="kiro-cli chat"
alias cld1='CLAUDE_CONFIG_DIR=~/.claude-1 claude --dangerously-skip-permissions'
alias cld2='CLAUDE_CONFIG_DIR=~/.claude-2 claude --dangerously-skip-permissions'
alias cld="codex --dangerously-bypass-approvals-and-sandbox"
alias kld="kiro-cli chat -a"
alias tk="tmux kill-server"
alias ta-drem="tmux -L drem -f '~/git/drem-orchestrator.git/master/.tmux.conf' attach"
alias t="drem-sx connect -c fastfetch fastfetch"
alias src="source ~/.zshrc"
alias vrc="nvim ~/.zshrc"
alias cns="$DOTFILES_DIR/sesh/new_session.sh"
alias wt="wt.sh"

ddshot() {
  local -a screenshots
  screenshots=(~/Documents/screenshots/*(om[1]N))

  if (( ${#screenshots} == 0 )); then
    print -u2 "No screenshots found in ~/Documents/screenshots"
    return 1
  fi

  scp -P 21337 ${MACHINE_SSH_KEY:+-i "$MACHINE_SSH_KEY"} -- "${screenshots[1]}" godinj@script.dremhome.org:~/
}

# Copy stdin or file contents to the clipboard.
# Mac: pbcopy, local Linux: wl-copy, remote/SSH: OSC 52 escape sequence.
# Usage: echo "text" | clip   or   clip file.txt
clip() {
  if command -v pbcopy &>/dev/null; then
    cat "$@" | pbcopy
  elif [ -z "$SSH_TTY" ] && command -v wl-copy &>/dev/null; then
    cat "$@" | wl-copy
  else
    local data
    data=$(cat "$@" | base64 | tr -d '\n')
    printf '\033]52;c;%s\a' "$data"
  fi
}
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

export NVM_DIR="$HOME/.nvm"
if command -v brew &>/dev/null; then
  [ -s "$(brew --prefix nvm)/nvm.sh" ] && \. "$(brew --prefix nvm)/nvm.sh"
  [ -s "$(brew --prefix nvm)/etc/bash_completion.d/nvm" ] && \. "$(brew --prefix nvm)/etc/bash_completion.d/nvm"
elif [ -s "$NVM_DIR/nvm.sh" ]; then
  \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
fi

# source ~/tmux-config/.tmux_init_script
source ~/tmux-config/scripts/fzf_init.zsh
eval "$(zoxide init zsh)"


if [ "$TERM_PROGRAM" = "iTerm.app" ] && [ -e "$HOME/.iterm2_shell_integration.zsh" ]; then
  source "$HOME/.iterm2_shell_integration.zsh"
fi

if [ -z "$TMUX" ]
 then
    clear
    drem-sx connect -c fastfetch fastfetch
fi

export PATH=$HOME/.toolbox/bin:$PATH

# Ensure docker group membership (interactive shells only)
if [[ -o interactive ]] && command -v docker &>/dev/null; then
  if ! id -Gn "$USER" | tr ' ' '\n' | grep -qx docker; then
    echo "Adding $USER to docker group (sudo required)..."
    sudo usermod -aG docker "$USER" && export _DOCKER_NEEDS_RELOAD=1
  elif ! groups | tr ' ' '\n' | grep -qx docker && [ -z "$_DOCKER_GROUP_RELOADED" ]; then
    export _DOCKER_GROUP_RELOADED=1
    exec newgrp docker
  fi
fi


# Kiro CLI post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh"
autoload -Uz compinit && compinit

# Set up brazil completion
[ -f /Users/jggodin/.brazil_completion/zsh_completion ] && source /Users/jggodin/.brazil_completion/zsh_completion
alias finch='sudo HOME=/home/jggodin DOCKER_CONFIG=/home/jggodin/.docker finch'
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
command -v mise >/dev/null 2>&1 && eval "$(mise activate zsh)"

# Added by AIM CLI
export PATH="$HOME/.aim/mcp-servers:$PATH"

# opencode
export PATH=/home/godinj/.opencode/bin:$PATH
export OPENCODE_MULTI_AUTH_CODEX_AUTH_FILE=/home/godinj/.codex/auth.json
export OPENCODE_MULTI_AUTH_PREFER_CODEX_LATEST=1
