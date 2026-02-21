Show the status of all git worktrees and feature branches in the current bare repo.

Steps:
1. Detect the bare repo root using `git rev-parse --git-common-dir`. If not inside a bare repo worktree, tell the user and stop.
2. Run `git worktree list` to show all worktrees
3. Determine the default branch (`git symbolic-ref --short HEAD` from the bare repo)
4. For each worktree/branch, run `git log --oneline <default-branch>..<branch> | wc -l` to count commits ahead
5. Run `git diff --stat <default-branch>..<branch>` for a file-change summary per branch
6. If a worktree has a CLAUDE.md, extract its mission line for context
7. Present a clear table with: worktree path, branch name, commits ahead, files changed, and mission/description
