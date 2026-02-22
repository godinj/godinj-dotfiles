#!/usr/bin/env bats
# Tests for wt/wt-helpers.sh pure functions.

setup() {
  load '../test_helper'
  source "$REPO_ROOT/wt/wt-helpers.sh" 2>/dev/null || true
}

# --- wt_ensure_prefix ---

@test "wt_ensure_prefix adds feature/ prefix to bare name" {
  run wt_ensure_prefix "auth"
  assert_success
  assert_output "feature/auth"
}

@test "wt_ensure_prefix preserves existing feature/ prefix" {
  run wt_ensure_prefix "feature/auth"
  assert_success
  assert_output "feature/auth"
}

@test "wt_ensure_prefix handles empty string" {
  run wt_ensure_prefix ""
  assert_success
  assert_output "feature/"
}

@test "wt_ensure_prefix handles name with slashes" {
  run wt_ensure_prefix "fix/login-bug"
  assert_success
  assert_output "feature/fix/login-bug"
}

# --- wt_project_name ---

@test "wt_project_name strips .git suffix" {
  run wt_project_name "/home/user/git/myproject.git"
  assert_success
  assert_output "myproject"
}

@test "wt_project_name handles dots in project name" {
  run wt_project_name "/home/user/git/my.dotfiles.git"
  assert_success
  assert_output "my.dotfiles"
}

@test "wt_project_name handles path without .git suffix" {
  run wt_project_name "/home/user/git/myproject"
  assert_success
  assert_output "myproject"
}

# --- wt_session_name ---

@test "wt_session_name with branch returns icon + project/branch" {
  run wt_session_name "myproject" "feature/auth"
  assert_success
  assert_output "$ICON_WORKTREE myproject/feature/auth"
}

@test "wt_session_name without branch returns project icon + project" {
  run wt_session_name "myproject"
  assert_success
  assert_output "$ICON_WORKTREE_PROJECT myproject"
}

@test "wt_session_name with empty branch string returns project icon + project" {
  run wt_session_name "myproject" ""
  assert_success
  assert_output "$ICON_WORKTREE_PROJECT myproject"
}

# --- wt_bare_name ---

@test "wt_bare_name with branch returns project/branch" {
  run wt_bare_name "myproject" "feature/auth"
  assert_success
  assert_output "myproject/feature/auth"
}

@test "wt_bare_name without branch returns project only" {
  run wt_bare_name "myproject"
  assert_success
  assert_output "myproject"
}

@test "wt_bare_name with empty branch string returns project only" {
  run wt_bare_name "myproject" ""
  assert_success
  assert_output "myproject"
}
