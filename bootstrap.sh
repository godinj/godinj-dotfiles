#!/usr/bin/env bash
set -euo pipefail

# Bootstrap godinj-dotfiles as a bare repo with worktrees.
#
# Usage:
#   bash bootstrap.sh                          # default repo URL
#   bash bootstrap.sh <repo-url>               # fork or alternate remote
#   bash <(curl -fsSL https://raw.githubusercontent.com/godinj/godinj-dotfiles/master/bootstrap.sh)

REPO_URL="${1:-git@github.com:godinj/godinj-dotfiles.git}"
BARE_DIR="$HOME/git/godinj-dotfiles.git"
DEFAULT_BRANCH="master"

info()  { printf "\033[1;34m::\033[0m %s\n" "$*"; }
ok()    { printf "\033[1;32m✓\033[0m  %s\n" "$*"; }
warn()  { printf "\033[1;33m!\033[0m  %s\n" "$*"; }
err()   { printf "\033[1;31m✗\033[0m  %s\n" "$*"; }

# ── Clone or migrate to bare repo ──────────────────────────────────────────

if [ -d "$BARE_DIR" ] && [ -d "$BARE_DIR/.git" ]; then
  # Regular clone masquerading as bare — migrate it
  info "Detected regular clone at $BARE_DIR — migrating to bare repo..."

  # Safety: working tree must be clean
  if ! git -C "$BARE_DIR" diff --quiet || ! git -C "$BARE_DIR" diff --cached --quiet; then
    err "Working tree at $BARE_DIR has uncommitted changes — aborting migration"
    exit 1
  fi

  # Safety: current branch HEAD must be pushed to origin
  local_head="$(git -C "$BARE_DIR" rev-parse HEAD)"
  current_branch="$(git -C "$BARE_DIR" symbolic-ref --short HEAD)"
  remote_head="$(git -C "$BARE_DIR" rev-parse "origin/$current_branch" 2>/dev/null || true)"
  if [ "$local_head" != "$remote_head" ]; then
    err "Branch $current_branch has unpushed commits — aborting migration"
    exit 1
  fi

  # Warn about stashes
  if [ -n "$(git -C "$BARE_DIR" stash list 2>/dev/null)" ]; then
    warn "Stashes exist and will be lost during migration"
  fi

  # Record existing worktrees (skip the main working tree)
  worktree_branches=()
  while IFS= read -r line; do
    wt_path="${line%% *}"
    # Skip the main working tree itself
    [ "$wt_path" = "$BARE_DIR" ] && continue
    wt_branch="$(git -C "$wt_path" symbolic-ref --short HEAD 2>/dev/null || true)"
    [ -n "$wt_branch" ] && worktree_branches+=("$wt_branch")
  done < <(git -C "$BARE_DIR" worktree list --porcelain | grep '^worktree ' | sed 's/^worktree //')

  # Record remote URL before we move anything
  CLONE_URL="$(git -C "$BARE_DIR" remote get-url origin)"

  # Rename → re-clone bare → restore worktrees → remove backup
  BACKUP_DIR="${BARE_DIR}.migrating"
  mv "$BARE_DIR" "$BACKUP_DIR"
  info "Backed up to $BACKUP_DIR"

  git clone --bare "$CLONE_URL" "$BARE_DIR"
  ok "Bare repo created at $BARE_DIR"

  # Fix remote.origin.fetch so that fetch + worktree add work
  git -C "$BARE_DIR" config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
  git -C "$BARE_DIR" fetch --all --quiet

  # Re-create feature worktrees
  for branch in "${worktree_branches[@]}"; do
    wt_dir="$BARE_DIR/$branch"
    info "Re-creating worktree for '$branch'..."
    git -C "$BARE_DIR" worktree add "$wt_dir" "$branch" 2>/dev/null \
      || git -C "$BARE_DIR" worktree add "$wt_dir" -b "$branch" "origin/$branch" 2>/dev/null \
      || warn "Could not re-create worktree for $branch"
  done

  rm -rf "$BACKUP_DIR"
  ok "Migration complete — removed backup"

elif [ -d "$BARE_DIR" ]; then
  ok "$BARE_DIR already exists — skipping clone"
else
  info "Cloning $REPO_URL as bare repo..."
  mkdir -p "$(dirname "$BARE_DIR")"
  git clone --bare "$REPO_URL" "$BARE_DIR"
  ok "Bare repo created at $BARE_DIR"
fi

# Fix remote.origin.fetch — bare repos don't set this by default,
# which prevents `git fetch` from updating remote tracking branches.
git -C "$BARE_DIR" config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'

# ── Create default branch worktree ──────────────────────────────────────────

WORKTREE_DIR="$BARE_DIR/$DEFAULT_BRANCH"

if [ -d "$WORKTREE_DIR" ]; then
  ok "Worktree $WORKTREE_DIR already exists — skipping"
else
  info "Creating worktree for '$DEFAULT_BRANCH'..."
  git -C "$BARE_DIR" worktree add "$WORKTREE_DIR" "$DEFAULT_BRANCH"
  ok "Worktree created at $WORKTREE_DIR"
fi

# ── Run install.sh from the worktree ────────────────────────────────────────

info "Launching install.sh..."
exec bash "$WORKTREE_DIR/install.sh"
