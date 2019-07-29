local ret_status="%(?:%{$FG[175]%}λ:%{$fg_bold[red]%}λ)"
#PROMPT='${ret_status} %{$FG[038]%}%2~ %{$reset_color%} $(git_prompt_info)'
PROMPT='${ret_status} %{$FG[038]%}%2~ %{$reset_color%}∴ '

ZSH_THEME_GIT_PROMPT_PREFIX="%{$FG[026]%}git:(%{$FG[002]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_DIRTY="%{$FG[026]%}) %{$FG[001]%}✗"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$FG[026]%})"
