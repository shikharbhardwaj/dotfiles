# Fish prompt matching the modified robbyrussell zsh theme
# (zsh/themes/robbyrussell_mod.zsh-theme).
#
#   λ <last-2-dirs> ∴
#
# - λ is bold magenta on success, bold red on failure (exit status).
# - The directory is the last 2 path components (zsh %2~), in cyan (256 #38).
# - ∴ (therefore) in the default color.
# Git info is intentionally omitted, matching the active zsh PROMPT line
# (the git_prompt_info variant is commented out upstream).

function fish_prompt --description 'Prompt — modified robbyrussell (λ <2dirs> ∴)'
    # λ colored by last command's exit status.
    if test $status -eq 0
        set_color FF5FFF --bold  # bright magenta (zsh FG[207])
    else
        set_color red --bold
    end
    echo -ns 'λ'
    set_color normal

    echo -ns ' '

    # Last 2 path components, with $HOME collapsed to ~ (zsh %2~).
    set -l pwd (string replace -r "^$HOME" '~' -- $PWD 2>/dev/null; or echo $PWD)
    set -l parts (string split / -- $pwd)
    # Drop leading empties from absolute paths so /a/b -> a/b not /b.
    while test (count $parts) -gt 1; and test -z "$parts[1]"
        set -e parts[1]
    end
    if test (count $parts) -gt 2
        set parts $parts[(math (count $parts)-1)..-1]
    end
    set_color 00AFD7  # teal/cyan (zsh FG[038])
    echo -ns (string join / -- $parts)
    set_color normal

    echo -ns ' ∴ '
end
