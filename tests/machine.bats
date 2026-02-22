#!/usr/bin/env bats
# Tests for machine.sh machine profile resolution.

setup() {
  load 'test_helper'

  # Create isolated temp directory structure for each test
  TEST_DIR="$(mktemp -d)"
  mkdir -p "$TEST_DIR/machines/mba"
  mkdir -p "$TEST_DIR/machines/default"
  export DOTFILES_DIR="$TEST_DIR"
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "reads machine name from .machine file" {
  echo "mba" > "$TEST_DIR/.machine"
  source "$REPO_ROOT/machine.sh"
  assert_equal "$MACHINE_NAME" "mba"
  assert_equal "$MACHINE_DIR" "$TEST_DIR/machines/mba"
}

@test "defaults to 'default' when .machine file is missing" {
  source "$REPO_ROOT/machine.sh"
  assert_equal "$MACHINE_NAME" "default"
  assert_equal "$MACHINE_DIR" "$TEST_DIR/machines/default"
}

@test "falls back with warning for unknown machine" {
  echo "nonexistent" > "$TEST_DIR/.machine"
  run bash -c "export DOTFILES_DIR='$TEST_DIR'; source '$REPO_ROOT/machine.sh'"
  assert_output --partial "Warning"
  assert_output --partial "nonexistent"
}

@test "ignores comment lines in .machine file" {
  printf '# this is a comment\nmba\n' > "$TEST_DIR/.machine"
  source "$REPO_ROOT/machine.sh"
  assert_equal "$MACHINE_NAME" "mba"
}
