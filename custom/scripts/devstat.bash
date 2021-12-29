#!/bin/bash

#set -euo pipefail
#IFS=$"\n\t"

source $HOME/custom/scripts/utils.bash

# declare -a repos=("instabase" "instabase_fork_001" "instabase_fork_002")
repos=("instabase" "instabase_fork_001" "instabase_fork_002")

function printStatus()
{
    status_table="repo branch clean"

    for repo in "${repos[@]}";
    do
        git_path="$HOME/Documents/dev/$repo"
        branch_name=$(git -C $git_path rev-parse --abbrev-ref HEAD)
        clean=''
        [[ -n $(git -C $git_path status -s) ]] && clean='✘'|| clean='✔'
        status_table="$status_table"$'\n'"$repo $branch_name $clean"
    done;

    printTable ' ' "$status_table"
}


function devstat() {
    if [[ -z $1 ]] || [[ $1 == "stat" ]]; then
        printStatus
    elif [[ $1 == "sw" ]] && [[ -n $2 ]]; then
        repo=${repos[$2]}
        echo "Switching to $repo"
        cd "$HOME/Documents/dev/$repo"
    fi
}

