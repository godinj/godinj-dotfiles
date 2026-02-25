#!/usr/bin/env bats
# Tests for wt/wt-doctor.sh checks.

setup() {
  load '../test_helper'

  TEST_HOME="$(mktemp -d)"
  TEST_GIT_BASE="$TEST_HOME/git"
  mkdir -p "$TEST_GIT_BASE"
  TEST_DOTFILES="$(mktemp -d)"
  TEST_MACHINE="$(mktemp -d)"
  mkdir -p "$TEST_DOTFILES/sesh/sessions"
  mkdir -p "$TEST_MACHINE/sesh/sessions"

  DOCTOR="$REPO_ROOT/wt/wt-doctor.sh"
}

teardown() {
  rm -rf "$TEST_HOME" "$TEST_DOTFILES" "$TEST_MACHINE"
}

# Helper: run wt-doctor with test overrides
run_doctor() {
  run env \
    WT_GIT_BASE="$TEST_GIT_BASE" \
    WT_DOTFILES_DIR="$TEST_DOTFILES" \
    MACHINE_DIR="$TEST_MACHINE" \
    bash "$DOCTOR"
}

# Helper: create a proper bare repo with a default branch worktree
create_bare_repo() {
  local name="$1"
  local branch="${2:-main}"
  local bare="$TEST_GIT_BASE/${name}.git"

  git init --bare "$bare" >/dev/null 2>&1

  # Create an initial commit so HEAD is valid
  local tmp
  tmp="$(mktemp -d)"
  git clone "$bare" "$tmp/work" >/dev/null 2>&1
  git -C "$tmp/work" commit --allow-empty -m "init" >/dev/null 2>&1
  git -C "$tmp/work" branch -M "$branch"
  git -C "$tmp/work" push origin "$branch" >/dev/null 2>&1
  rm -rf "$tmp"

  # Point HEAD at the default branch
  git -C "$bare" symbolic-ref HEAD "refs/heads/$branch"

  # Create worktree for the default branch
  git -C "$bare" worktree add "$bare/$branch" "$branch" >/dev/null 2>&1
}

# ── check_bare_repos ────────────────────────────────────────────────────────

@test "doctor: healthy bare repo passes" {
  create_bare_repo "myproject"

  run_doctor
  assert_success
  assert_output --partial "myproject.git — main/ exists"
}

@test "doctor: bare repo missing default branch worktree is flagged" {
  create_bare_repo "broken"
  rm -rf "$TEST_GIT_BASE/broken.git/main"

  run_doctor
  assert_failure
  assert_output --partial "missing default branch worktree: main/"
}

@test "doctor: regular clone named .git is flagged" {
  mkdir -p "$TEST_GIT_BASE/fake.git/.git"

  run_doctor
  assert_failure
  assert_output --partial "regular clone named *.git"
}

# ── check_sesh_paths ────────────────────────────────────────────────────────

@test "doctor: existing sesh path passes" {
  create_bare_repo "good"
  cat > "$TEST_DOTFILES/sesh/sessions/test.toml" <<EOF
[[session]]
name = "good"
path = "$TEST_GIT_BASE/good.git/main/"
EOF

  run_doctor
  assert_success
  assert_output --partial "$TEST_GIT_BASE/good.git/main/"
}

@test "doctor: missing sesh path is flagged" {
  cat > "$TEST_DOTFILES/sesh/sessions/test.toml" <<EOF
[[session]]
name = "gone"
path = "$TEST_GIT_BASE/nonexistent.git/main/"
EOF

  run_doctor
  assert_failure
  assert_output --partial "Path does not exist"
}

@test "doctor: stale non-bare sesh path is flagged" {
  create_bare_repo "staleproject"
  # Create the non-bare path so it exists on disk (doesn't fail existence check)
  mkdir -p "$TEST_GIT_BASE/staleproject/somedir"

  cat > "$TEST_DOTFILES/sesh/sessions/test.toml" <<EOF
[[session]]
name = "stale"
path = "~/git/staleproject/somedir"
EOF

  # Set HOME so ~/git resolves to TEST_GIT_BASE
  run env \
    HOME="$TEST_HOME" \
    WT_GIT_BASE="$TEST_GIT_BASE" \
    WT_DOTFILES_DIR="$TEST_DOTFILES" \
    MACHINE_DIR="$TEST_MACHINE" \
    bash "$DOCTOR"

  assert_failure
  assert_output --partial "Stale non-bare path"
}
