#!/usr/bin/env bats
# Tests for sesh/sesh_tree_list.sh AWK pipeline.
# Tested by piping sample input to the script — no sourcing needed.

setup() {
  load '../test_helper'
  TREE_SCRIPT="$REPO_ROOT/sesh/sesh_tree_list.sh"
}

@test "standalone session passes through unchanged" {
  input="T 󱘖 fastfetch"
  run bash -c "echo '$input' | '$TREE_SCRIPT'"
  assert_success
  # Output format: ORIGINAL<TAB>DISPLAY — standalone lines have same original and display
  assert_output "T 󱘖 fastfetch	T 󱘖 fastfetch"
}

@test "child groups under parent with tree chars" {
  input="T 󱁤 myproject
T 󰀜 myproject/feature/auth"
  run bash -c "printf '%s\n' 'T 󱁤 myproject' 'T 󰀜 myproject/feature/auth' | '$TREE_SCRIPT'"
  assert_success
  # Children emitted before parent; single child gets └──
  assert_line --index 0 --partial "└──"
  assert_line --index 0 --partial "feature/auth"
  assert_line --index 1 --partial "T 󱁤 myproject"
}

@test "multiple children get tree chars in correct order" {
  run bash -c "printf '%s\n' 'T 󱁤 proj' 'T 󰀜 proj/feature/a' 'T 󰀜 proj/feature/b' | '$TREE_SCRIPT'"
  assert_success
  # Two children: last emitted first with ├──, first emitted last with └──
  assert_line --index 0 --partial "├──"
  assert_line --index 0 --partial "feature/b"
  assert_line --index 1 --partial "└──"
  assert_line --index 1 --partial "feature/a"
  assert_line --index 2 --partial "T 󱁤 proj"
}

@test "orphan child with no parent passes through standalone" {
  run bash -c "echo 'T 󰀜 orphan/feature/x' | '$TREE_SCRIPT'"
  assert_success
  # No parent in list, so it passes through as-is
  assert_output "T 󰀜 orphan/feature/x	T 󰀜 orphan/feature/x"
}
