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
err()   { printf "\033[1;31m✗\033[0m  %s\n" "$*"; }

# ── Clone bare repo ─────────────────────────────────────────────────────────

if [ -d "$BARE_DIR" ]; then
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
