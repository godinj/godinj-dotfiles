#!/usr/bin/env bats
# Tests for sesh/sesh_toggle_fold.sh

setup() {
  load '../test_helper'
  TOGGLE_SCRIPT="$REPO_ROOT/sesh/sesh_toggle_fold.sh"
  FOLD_DIR="$(mktemp -d)"
  export SESH_FOLD_FILE="$FOLD_DIR/fold_state"
}

teardown() {
  rm -rf "$FOLD_DIR"
}

@test "toggle adds parent to empty fold file" {
  run bash -c "SESH_FOLD_FILE='$SESH_FOLD_FILE' bash '$TOGGLE_SCRIPT' 'T 󱁤 myproject'"
  assert_success
  assert_equal "$(cat "$SESH_FOLD_FILE")" "myproject"
}

@test "toggle removes existing parent (unfold)" {
  printf '%s\n' "myproject" > "$SESH_FOLD_FILE"
  run bash -c "SESH_FOLD_FILE='$SESH_FOLD_FILE' bash '$TOGGLE_SCRIPT' 'T 󱁤 myproject'"
  assert_success
  # File should be empty (no entries)
  refute grep -qxF "myproject" "$SESH_FOLD_FILE"
}

@test "toggle on child line extracts and toggles parent" {
  run bash -c "SESH_FOLD_FILE='$SESH_FOLD_FILE' bash '$TOGGLE_SCRIPT' 'T 󰀜 myproject/feature/auth'"
  assert_success
  assert_equal "$(cat "$SESH_FOLD_FILE")" "myproject"
}

@test "creates fold file directory if missing" {
  rm -rf "$FOLD_DIR"
  export SESH_FOLD_FILE="$FOLD_DIR/subdir/fold_state"
  run bash -c "SESH_FOLD_FILE='$SESH_FOLD_FILE' bash '$TOGGLE_SCRIPT' 'T 󱁤 proj'"
  assert_success
  assert_file_exists "$SESH_FOLD_FILE"
}

@test "no-op without SESH_FOLD_FILE" {
  run bash -c "unset SESH_FOLD_FILE; bash '$TOGGLE_SCRIPT' 'T 󱁤 proj'"
  assert_success
  # No fold file should be created
  [ ! -f "$FOLD_DIR/fold_state" ]
}

@test "preserves other entries in fold file" {
  printf '%s\n' "alpha" "beta" "gamma" > "$SESH_FOLD_FILE"
  run bash -c "SESH_FOLD_FILE='$SESH_FOLD_FILE' bash '$TOGGLE_SCRIPT' 'T 󱁤 beta'"
  assert_success
  # beta should be removed, alpha and gamma preserved
  run cat "$SESH_FOLD_FILE"
  assert_line --index 0 "alpha"
  assert_line --index 1 "gamma"
  refute_output --partial "beta"
}
