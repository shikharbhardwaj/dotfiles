if status is-interactive
    set -gx TERM xterm-256color
end

# PATH
fish_add_path ~/.local/bin
fish_add_path ~/bin
fish_add_path /usr/local/go/bin

set -gx GOPATH ~/Documents/workspace/go
fish_add_path $GOPATH/bin

set -gx PKG_CONFIG_PATH "$PKG_CONFIG_PATH:/usr/local/lib/pkgconfig"

# ls colors
if test -f ~/.dircolors
    set -gx LS_COLORS (dircolors -b ~/.dircolors | string match -r "LS_COLORS='(.*)';" -g)
end

# Aliases
abbr -a ':q' exit
abbr -a ':e' nvim

set -gx EDITOR nvim
set -gx VISUAL nvim

function tmux
    env TERM=xterm-256color tmux -2 -u $argv
end

function vim
    nvim $argv
end

# Version managers
if type -q mise
    mise activate fish | source
end

if type -q nodenv
    nodenv init - fish | source
end

if type -q pyenv
    pyenv init --path | source
end

# Local, machine-specific overrides (gitignored)
set -l dotfiles_dir (realpath (dirname (status --current-filename))/..)
if test -f $dotfiles_dir/custom/scripts/extra.fish
    source $dotfiles_dir/custom/scripts/extra.fish
end
