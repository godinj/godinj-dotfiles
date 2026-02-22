Condense post-merge history into a clean linear sequence. The argument should be a base commit (hash, tag, or ref) — everything after it gets condensed.

Steps:
1. Run `git status` to ensure the working tree is clean. If not, warn the user and stop.
2. Validate the base ref: run `git rev-parse --verify $ARGUMENTS^{commit}`. If invalid, tell the user and stop.
3. Check the range is non-empty: run `git rev-list --count --first-parent $ARGUMENTS..HEAD`. If 0, tell the user there is nothing to condense and stop.
4. Preview the range: run `git log --oneline --first-parent $ARGUMENTS..HEAD` and show the output with the total commit count.
5. Ask the user which condensing strategy to use:
   - **Single squash** — collapse everything into one commit with a generated summary message.
   - **Per-feature linear** — flatten merge commits into one commit per feature while preserving direct commits, producing a clean linear history.
6. Create a backup ref before any destructive operation:
   ```
   git update-ref refs/backup/condense-$(date +%Y%m%d-%H%M%S) HEAD
   ```
   Show the backup ref name so the user knows how to restore.

**Single squash strategy:**
7a. Run `git reset --soft $ARGUMENTS`.
8a. Generate a summary commit message from the condensed commits (list the features/changes merged).
9a. Run `git commit` with the generated message. Let the user review/edit the message first.

**Per-feature linear strategy:**
7b. Parse `git log --first-parent --reverse --format='%H %P %s' $ARGUMENTS..HEAD` to classify each commit:
    - **Merge commit** (2+ parents): extract the feature name from the subject (strip "Merge branch 'feature/...'"-style boilerplate). Capture its diff: `git diff $COMMIT^1 $COMMIT`.
    - **Direct commit** (1 parent): capture its diff the same way: `git diff $COMMIT^ $COMMIT`. Preserve its original subject and body.
8b. Group consecutive merges of the same feature into a single patch (concatenate diffs, deduplicate hunks).
9b. Run `git reset --hard $ARGUMENTS`.
10b. Replay each patch in order:
    - `git apply --index <patch>` then `git commit -m "<message>"`.
    - For feature merges, use a descriptive message (e.g. "Add mouse-mode support") instead of "Merge branch ...".
    - For direct commits, reuse the original commit message.
11b. If `git apply` fails on a patch, show the failing patch content and ask the user how to proceed (skip, manually resolve, or abort and restore from backup).

**After either strategy:**
12. Show the result: `git log --oneline --graph $ARGUMENTS..HEAD`.
13. Warn the user that a force-push (`git push --force-with-lease`) will be needed if this branch has been pushed before. Do NOT force-push automatically.
14. Remind the user of the backup ref and that `git reset --hard <backup-ref>` will fully restore the original state.
