Sync all feature worktrees by rebasing them onto the default branch. This pushes merged changes out to every active feature branch.

Steps:
1. Run `git status` to ensure the working tree is clean. If not, warn and stop.
2. Detect the bare repo root and default branch name.
3. Run `git worktree list` to discover all worktrees and their branches.
4. For each worktree branch that is NOT the default branch:
   a. Show the branch name and how many commits it is behind the default branch (`git rev-list <branch>..<default> --count`).
   b. If 0 commits behind, skip it (already up to date).
   c. Run `git rebase <default-branch> <branch>` to rebase the feature branch.
   d. If the rebase has conflicts:
      - List the conflicting files.
      - For each conflict, read the file and resolve it, preserving the feature branch's intent while incorporating the default branch's changes.
      - For CLAUDE.md conflicts, keep the feature branch's version (it has feature-specific instructions).
      - Stage resolved files and `git rebase --continue`.
   e. Report success or failure for each branch.
5. Present a summary table: branch name, status (rebased / already up-to-date / failed), commits rebased.
