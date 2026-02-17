#!/bin/zsh

export curr_branch=$(git branch --show-current)
export time_stamp=$(date "+%y%m%d-%H%M")
export tmp_branch="$curr_branch-$time_stamp"

echo "time stamp: $time_stamp"

git stash
git checkout -b $tmp_branch
git checkout $curr_branch
git rebase -i origin/mainline && git stash pop
