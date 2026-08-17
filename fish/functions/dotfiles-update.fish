# Update the dotfiles repo: fetch + fast-forward pull, then re-link.
function dotfiles-update --description "Pull latest dotfiles and re-run the linker"
    set -f repo (realpath (dirname (status --current-filename))/../..)
    test -d "$repo/.git"; or return

    set -f upstream (git -C $repo rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)
    if test -z "$upstream"
        echo (set_color brred)"dotfiles: no upstream tracking branch set"(set_color normal)
        return 1
    end

    echo (set_color brcyan)"Fetching dotfiles…"(set_color normal)
    git -C $repo fetch --quiet --no-tags
    or return

    set -f head (git -C $repo rev-parse --short HEAD)
    set -f remote (git -C $repo rev-parse --short '@{u}')
    if test "$head" = "$remote"
        echo (set_color green)"dotfiles already up to date at $head"(set_color normal)
        return
    end

    git -C $repo pull --ff-only
    or return

    echo (set_color brcyan)"Re-running dotbot linker…"(set_color normal)
    cd $repo
    and ./install
end
