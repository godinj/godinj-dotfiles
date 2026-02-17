#!/bin/zsh

export curr_branch=$(git branch --show-current)

git stash
git checkout mainline
git pull origin mainline
git checkout $curr_branch
git stash pop
