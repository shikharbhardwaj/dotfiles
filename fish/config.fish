if status is-interactive
    set -gx TERM xterm-256color
    # Warn if the dotfiles repo is behind upstream.
    dotfiles_status
    # Tell herdr which host this workspace lives on ($hostname token in its sidebar).
    if set -q HERDR_WORKSPACE_ID
        herdr workspace report-metadata $HERDR_WORKSPACE_ID --source hostname \
            --token hostname=(prompt_hostname) >/dev/null 2>&1
    end
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


# Local, machine-specific overrides (gitignored)
set -l dotfiles_dir (realpath (dirname (status --current-filename))/..)
if test -f $dotfiles_dir/custom/scripts/extra.fish
    source $dotfiles_dir/custom/scripts/extra.fish
end

$HOME/.local/bin/mise activate fish | source # added by https://mise.run/fish
