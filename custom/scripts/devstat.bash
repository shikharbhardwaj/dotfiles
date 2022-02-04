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

function createcp() {
    if [[ -z $1  ]] || [[ -z $2 ]] || [[ -z $3 ]]; then
        echo "Parameters: commit-id base-branch commit-message"
    else
        commit_id=$1
        base_branch=$2
        commit_message=$3
        cp_branch=pr/cp/$base_branch-$commit_message

        echo "Creating and pushing CP for commit ID $commit_id from base branch $base_branch to branch $cp_branch"

        git checkout -b $base_branch
        git pull
        git checkout -b $cp_branch
        git cherry-pick $commit_id
        git push origin $cp_branch
    fi
}

function devstat() {
    if [[ -z $1 ]] || [[ $1 == "stat" ]]; then
        printStatus
    elif [[ $1 == "sw" ]] && [[ -n $2 ]]; then
        repo=${repos[$2]}
        echo "Switching to $repo"
        cd "$HOME/Documents/dev/$repo"
    elif [[ $1 == "cp" ]]; then
        createcp $2 $3 $4
    fi
}



