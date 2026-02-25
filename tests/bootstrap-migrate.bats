#!/usr/bin/env bats
# Tests for bootstrap.sh regular-clone → bare-repo migration.

setup() {
  load 'test_helper'

  TEST_HOME="$(mktemp -d)"
  TEST_GIT_BASE="$TEST_HOME/git"
  mkdir -p "$TEST_GIT_BASE"

  # Create a "remote" bare repo to clone from
  REMOTE_BARE="$(mktemp -d)/remote.git"
  git init --bare "$REMOTE_BARE" >/dev/null 2>&1

  # Seed it with an initial commit on master
  local tmp
  tmp="$(mktemp -d)"
  git clone "$REMOTE_BARE" "$tmp/work" >/dev/null 2>&1
  git -C "$tmp/work" commit --allow-empty -m "init" >/dev/null 2>&1
  git -C "$tmp/work" branch -M master
  git -C "$tmp/work" push origin master >/dev/null 2>&1

  # Add a feature branch
  git -C "$tmp/work" checkout -b feature/test-feat >/dev/null 2>&1
  git -C "$tmp/work" commit --allow-empty -m "feat" >/dev/null 2>&1
  git -C "$tmp/work" push origin feature/test-feat >/dev/null 2>&1
  rm -rf "$tmp"

  BOOTSTRAP="$REPO_ROOT/bootstrap.sh"
}

teardown() {
  rm -rf "$TEST_HOME" "$(dirname "$REMOTE_BARE")"
}

# Helper: create a regular clone at the *.git path (simulates the problem)
create_regular_clone() {
  local dest="$TEST_GIT_BASE/godinj-dotfiles.git"
  git clone "$REMOTE_BARE" "$dest" >/dev/null 2>&1
  git -C "$dest" checkout master >/dev/null 2>&1
}

# Helper: create a regular clone with a linked worktree
create_regular_clone_with_worktree() {
  create_regular_clone
  local dest="$TEST_GIT_BASE/godinj-dotfiles.git"
  git -C "$dest" worktree add "$dest/feature/test-feat" feature/test-feat >/dev/null 2>&1
}

# Helper: run bootstrap.sh with overridden paths (skip install.sh via env)
run_bootstrap() {
  # We override BARE_DIR and REPO_URL, and stub out `exec bash` to prevent
  # install.sh from running (it won't exist in our test repo)
  run env \
    HOME="$TEST_HOME" \
    bash -c "
      REPO_URL='$REMOTE_BARE'
      BARE_DIR='$TEST_GIT_BASE/godinj-dotfiles.git'
      DEFAULT_BRANCH='master'

      $(grep -A2 '^info()' "$BOOTSTRAP" | head -4)
      $(grep -A2 '^ok()' "$BOOTSTRAP" | head -1)
      $(grep -A2 '^warn()' "$BOOTSTRAP" | head -1)
      $(grep -A2 '^err()' "$BOOTSTRAP" | head -1)

      # Source the clone/migrate section and worktree section, but not exec install.sh
      $(sed -n '/^# ── Clone or migrate/,/^# ── Run install.sh/{ /^# ── Run install.sh/d; p; }' "$BOOTSTRAP")
    "
}

# ── Migration tests ────────────────────────────────────────────────────────

@test "migrate: regular clone is converted to bare repo" {
  create_regular_clone

  run_bootstrap

  assert_success
  assert_output --partial "migrating to bare repo"
  assert_output --partial "Migration complete"

  # Result should be a bare repo (no .git subdirectory)
  assert [ ! -d "$TEST_GIT_BASE/godinj-dotfiles.git/.git" ]
  # Should be recognized as bare
  run git -C "$TEST_GIT_BASE/godinj-dotfiles.git" rev-parse --is-bare-repository
  assert_output "true"
}

@test "migrate: default branch worktree is created after migration" {
  create_regular_clone

  run_bootstrap

  assert_success
  assert [ -d "$TEST_GIT_BASE/godinj-dotfiles.git/master" ]
}

@test "migrate: feature worktrees are re-created after migration" {
  create_regular_clone_with_worktree

  run_bootstrap

  assert_success
  assert_output --partial "Re-creating worktree for 'feature/test-feat'"
  assert [ -d "$TEST_GIT_BASE/godinj-dotfiles.git/feature/test-feat" ]
}

@test "migrate: dirty working tree aborts migration" {
  create_regular_clone
  # Create uncommitted changes
  echo "dirty" > "$TEST_GIT_BASE/godinj-dotfiles.git/dirty-file.txt"
  git -C "$TEST_GIT_BASE/godinj-dotfiles.git" add dirty-file.txt

  run_bootstrap

  assert_failure
  assert_output --partial "uncommitted changes"
  # Original clone should still be there, untouched
  assert [ -d "$TEST_GIT_BASE/godinj-dotfiles.git/.git" ]
}

@test "migrate: unpushed commits abort migration" {
  create_regular_clone
  git -C "$TEST_GIT_BASE/godinj-dotfiles.git" commit --allow-empty -m "local only" >/dev/null 2>&1

  run_bootstrap

  assert_failure
  assert_output --partial "unpushed commits"
  assert [ -d "$TEST_GIT_BASE/godinj-dotfiles.git/.git" ]
}

@test "migrate: already-bare repo is left alone" {
  # Clone bare directly — this is the happy path
  git clone --bare "$REMOTE_BARE" "$TEST_GIT_BASE/godinj-dotfiles.git" >/dev/null 2>&1

  run_bootstrap

  assert_success
  assert_output --partial "already exists"
  refute_output --partial "migrating"
}

@test "migrate: backup is removed after successful migration" {
  create_regular_clone

  run_bootstrap

  assert_success
  assert [ ! -d "$TEST_GIT_BASE/godinj-dotfiles.git.migrating" ]
}
