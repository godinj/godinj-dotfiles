# Worktree Creation Agent

Create a new git worktree for parallel feature development.

## Steps

1. Detect the bare repo root using `git rev-parse --git-common-dir`. If not inside a bare repo worktree, tell the user and stop.
2. Create the worktree: `wt new <branch-name>`
   - If `wt` is not available, fall back to: `git worktree add ../<branch-name> -b <branch-name>`
3. Read any existing PRD.md, README.md, or project docs to understand the project scope
4. Ask the user what the worktree's mission should be if it's not obvious from the branch name
5. Create a CLAUDE.md in the new worktree with:
   - Mission statement
   - Build & Run commands (detect from existing build system: Makefile, CMakeLists.txt, package.json, Cargo.toml, etc.)
   - Architecture overview (summarize from main CLAUDE.md if one exists)
   - What to Implement (detailed breakdown)
   - Key files to modify/create
   - Verification criteria
   - Conventions (inherit from main CLAUDE.md)
6. Commit the CLAUDE.md in the worktree branch
7. If the main worktree has a CLAUDE.md with a worktree table, update it with the new entry and commit
8. Report the worktree path so the user can `cd` into it or use `sesh` to connect

## Usage

User invokes this by asking to create a new worktree or feature branch.
Example: "wt new feature/auth" or "create a new worktree for authentication"
