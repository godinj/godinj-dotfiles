#!/bin/zsh

export curr_branch=$(git branch --show-current)
export time_stamp=$(date "+%y-%m-%d")

message=$1
# echo "file: $file"
if [ -z "$message" ]; then
  echo "no message found, defaulting to date as message."
  message="changes as of $time_stamp"
fi

echo "debug message: $message"

git stash
git checkout main
git pull origin main
git stash pop
git add .
git commit -m "$message" 
git push origin main
git checkout $curr_branch
git rebase -i origin/main
