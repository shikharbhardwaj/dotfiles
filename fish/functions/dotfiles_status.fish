# Print a one-line warning when the dotfiles repo is behind its upstream.
# The remote is fetched at most once a day (see _dotfiles_maybe_fetch);
# the HEAD-vs-upstream comparison is local and runs every shell.
function dotfiles_status --description "Warn if dotfiles repo is behind upstream"
    # Resolve the dotfiles repo from this function file's location.
    set -f repo (realpath (dirname (status --current-filename))/../..)
    test -d "$repo/.git"; or return

    # Refresh remote refs at most once per day (throttled, non-blocking).
    _dotfiles_maybe_fetch $repo

    # Upstream of the current branch (e.g. origin/master). Bail if none.
    set -f upstream (git -C $repo rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)
    test -n "$upstream"; or return

    set -f head (git -C $repo rev-parse --short HEAD 2>/dev/null)
    set -f remote (git -C $repo rev-parse --short '@{u}' 2>/dev/null)
    test -n "$head"; and test -n "$remote"; or return

    if test "$head" != "$remote"
        set -f branch (git -C $repo rev-parse --abbrev-ref HEAD 2>/dev/null)
        set -l behind (git -C $repo rev-list --count HEAD..'@{u}' 2>/dev/null)
        set -l ahead  (git -C $repo rev-list --count '@{u}'..HEAD 2>/dev/null)
        set -l parts
        test "$behind" -gt 0 2>/dev/null; and set -a parts "behind by $behind"
        test "$ahead"  -gt 0 2>/dev/null; and set -a parts "ahead by $ahead"
        set -l summary (string join ', ' -- $parts)

        echo (set_color bryellow)"↻ dotfiles ($branch) outdated: $summary — run `dotfiles-update`"(set_color normal)
    end
end

# Fetch the dotfiles remote at most once per day. Non-blocking: spawns a
# detached fetch so a slow network never delays shell startup. The last
# fetch time is recorded in a cache file so every shell agrees on cadence.
function _dotfiles_maybe_fetch --description "Throttled daily git fetch for the dotfiles repo"
    set -f repo $argv[1]
    set -f stamp_dir ~/.cache/dotfiles
    set -f stamp $stamp_dir/last_fetch
    set -f ttl 86400 # 24 hours in seconds

    # Decide whether to fetch based on the existing stamp.
    set -l do_fetch 1
    if test -f $stamp
        set -l mtime (stat -c %Y $stamp 2>/dev/null; or gstat -c %Y $stamp 2>/dev/null; or echo 0)
        set -l now (date +%s)
        if test "$now" -lt (math "$mtime + $ttl")
            set do_fetch 0
        end
    end

    test $do_fetch -eq 1; or return

    # Refresh the stamp now so concurrent shells don't all fetch at once.
    mkdir -p $stamp_dir
    date +%s > $stamp

    # Detached, quiet fetch — ignore failure (offline / no remote).
    nohup git -C $repo fetch --quiet --no-tags >/dev/null 2>&1 &
    disown >/dev/null 2>&1
end
