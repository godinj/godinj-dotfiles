#!/usr/bin/env bats
# Tests for sesh/sesh_tree_list.sh AWK pipeline.
# Tested by piping sample input to the script — no sourcing needed.

setup() {
  load '../test_helper'
  TREE_SCRIPT="$REPO_ROOT/sesh/sesh_tree_list.sh"
  FOLD_DIR="$(mktemp -d)"
  FOLD_FILE="$FOLD_DIR/fold_state"
}

teardown() {
  rm -rf "$FOLD_DIR"
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

# --- Fold state tests ---

@test "folded parent hides children and shows collapsed indicator with count" {
  printf '%s\n' "proj" > "$FOLD_FILE"
  run bash -c "export SESH_FOLD_FILE='$FOLD_FILE'; printf '%s\n' 'T 󱁤 proj' 'T 󰀜 proj/feature/a' 'T 󰀜 proj/feature/b' | '$TREE_SCRIPT'"
  assert_success
  # Only one line: the collapsed parent
  assert_equal "$(echo "$output" | wc -l | tr -d ' ')" "1"
  assert_output --partial "▸"
  assert_output --partial "[2]"
  assert_output --partial "T 󱁤 proj"
}

@test "expanded parent with fold file shows expand indicator" {
  touch "$FOLD_FILE"
  run bash -c "export SESH_FOLD_FILE='$FOLD_FILE'; printf '%s\n' 'T 󱁤 proj' 'T 󰀜 proj/feature/a' | '$TREE_SCRIPT'"
  assert_success
  # Parent line (last) should have ▾ indicator
  assert_line --index 1 --partial "▾"
  assert_line --index 1 --partial "T 󱁤 proj"
  # Child still has tree chars
  assert_line --index 0 --partial "└──"
}

@test "mixed fold state: one folded one expanded" {
  printf '%s\n' "alpha" > "$FOLD_FILE"
  run bash -c "export SESH_FOLD_FILE='$FOLD_FILE'; printf '%s\n' 'T 󱁤 alpha' 'T 󰀜 alpha/feature/x' 'T 󱁤 beta' 'T 󰀜 beta/feature/y' | '$TREE_SCRIPT'"
  assert_success
  # alpha is folded: 1 line with ▸
  assert_output --partial "▸"
  assert_output --partial "[1]"
  # beta is expanded: child + parent with ▾
  assert_output --partial "└──"
  assert_output --partial "▾"
}

@test "standalone session unchanged with fold file present" {
  touch "$FOLD_FILE"
  run bash -c "export SESH_FOLD_FILE='$FOLD_FILE'; echo 'T 󱘖 fastfetch' | '$TREE_SCRIPT'"
  assert_success
  assert_output "T 󱘖 fastfetch	T 󱘖 fastfetch"
}

@test "missing fold file treated as all-expanded" {
  run bash -c "export SESH_FOLD_FILE='$FOLD_DIR/nonexistent'; printf '%s\n' 'T 󱁤 proj' 'T 󰀜 proj/feature/a' | '$TREE_SCRIPT'"
  assert_success
  # Should behave as expanded with ▾ indicator (fold file is set but missing)
  assert_line --index 1 --partial "▾"
  assert_line --index 0 --partial "└──"
}

@test "ORIGINAL column unchanged for folded parent" {
  printf '%s\n' "proj" > "$FOLD_FILE"
  run bash -c "export SESH_FOLD_FILE='$FOLD_FILE'; printf '%s\n' 'T 󱁤 proj' 'T 󰀜 proj/feature/a' | '$TREE_SCRIPT'"
  assert_success
  # ORIGINAL (field 1 before tab) must be the unmodified sesh line
  original="${output%%	*}"
  assert_equal "$original" "T 󱁤 proj"
}
