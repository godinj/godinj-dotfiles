#!/usr/bin/env bats
# Tests for sesh/icons.sh icon constants.

setup() {
  load '../test_helper'
  source "$REPO_ROOT/sesh/icons.sh"
}

@test "ICON_TOOL is defined and non-empty" {
  assert [ -n "$ICON_TOOL" ]
}

@test "ICON_CONFIG is defined and non-empty" {
  assert [ -n "$ICON_CONFIG" ]
}

@test "ICON_PROJECT is defined and non-empty" {
  assert [ -n "$ICON_PROJECT" ]
}

@test "ICON_WORKTREE is defined and non-empty" {
  assert [ -n "$ICON_WORKTREE" ]
}

@test "ICON_WORKTREE_PROJECT is defined and non-empty" {
  assert [ -n "$ICON_WORKTREE_PROJECT" ]
}
