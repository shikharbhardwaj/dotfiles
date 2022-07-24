alias tmux="TERM=xterm-256color tmux -2 -u"
alias ":q"="exit"
alias ":e"="vim"

# Colorscheme config
BASE16_SHELL="$HOME/custom/colorschemes/base16-default-dark.sh"
SOLARIZED="$HOME/custom/colorschemes/solarized.sh"
CURRENT_SCHEME="$SOLARIZED"

# Settings for dicolors
eval `dircolors ~/.dircolors`

# [[ -s $CURRENT_SCHEME ]] && source $CURRENT_SCHEME

#export TERM="xterm-256color"

export CPATH="$HOME/custom/include"

export PATH="$HOME/custom/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

#Settings for makefiles
export MAKEFILES=$HOME/custom/Makefile
