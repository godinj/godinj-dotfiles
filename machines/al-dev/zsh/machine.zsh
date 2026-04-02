# Gruvbox-inspired prompt colors for rkj-repos layout

PROMPT='%{$fg_bold[yellow]%}┌─[%{$fg_bold[green]%}%n%b%{$fg[yellow]%}@%{$fg[cyan]%}%m%{$fg_bold[yellow]%}]%{$reset_color%} - %{$fg_bold[yellow]%}[%{$fg_bold[white]%}%~%{$fg_bold[yellow]%}]%{$reset_color%} - %{$fg_bold[yellow]%}[%b%{$fg[magenta]%}%D{"%Y-%m-%d %I:%M:%S"}%b%{$fg_bold[yellow]%}]
%{$fg_bold[yellow]%}└─[%{$fg_bold[red]%}%?$(retcode)%{$fg_bold[yellow]%}] <$(mygit)$(hg_prompt_info)>%{$reset_color%} '

ZSH_THEME_GIT_PROMPT_ADDED='%{$fg[cyan]%}+'
ZSH_THEME_GIT_PROMPT_MODIFIED='%{$fg[yellow]%}✱'
ZSH_THEME_GIT_PROMPT_DELETED='%{$fg[red]%}✗'
ZSH_THEME_GIT_PROMPT_RENAMED='%{$fg[cyan]%}➦'
ZSH_THEME_GIT_PROMPT_UNMERGED='%{$fg[magenta]%}✂'
ZSH_THEME_GIT_PROMPT_UNTRACKED='%{$fg[cyan]%}✈'

ZSH_THEME_GIT_PROMPT_PREFIX='%{$fg[green]%}'
ZSH_THEME_GIT_PROMPT_SUFFIX='%{$reset_color%}'
