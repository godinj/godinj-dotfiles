Merge a feature branch back into the current branch. The argument should be a branch name (e.g., "feature/auth").

Steps:
1. Run `git status` to ensure the working tree is clean. If not, warn the user and stop.
2. Run `git log --oneline HEAD..$ARGUMENTS` to show what's being merged
3. Run `git merge $ARGUMENTS`
4. If there are conflicts:
   - List all conflicting files
   - For each conflict, read the file and resolve it intelligently based on the intent of both branches
   - Prefer keeping both sides' changes when they don't logically conflict
   - For CLAUDE.md conflicts, keep the current branch's version but incorporate any useful info from the feature branch
   - Stage resolved files and complete the merge commit
5. Detect the build system and verify the merge compiles:
   - `Makefile` -> `make`
   - `CMakeLists.txt` -> `cmake --build build`
   - `package.json` -> `npm run build` or `npm test`
   - `Cargo.toml` -> `cargo build`
   - If no build system detected, skip this step
6. Report what was merged and whether the build succeeds
7. Suggest removing the worktree with `wt rm $ARGUMENTS` if the feature is complete
