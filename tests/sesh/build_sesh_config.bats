#!/usr/bin/env bats
# Tests for build_sesh_config.sh functions (icon_for_file, prepend_icon, prepend_worktree_icon).
# Functions are extracted via sed to avoid top-level side effects (set -euo pipefail, mkdir, cat).

setup() {
  load '../test_helper'

  # Source icon definitions directly
  source "$REPO_ROOT/sesh/icons.sh"

  # Extract functions from build_sesh_config.sh (they start at column 0)
  eval "$(sed -n '/^icon_for_file()/,/^}/p' "$REPO_ROOT/sesh/build_sesh_config.sh")"
  eval "$(sed -n '/^prepend_icon()/,/^}/p' "$REPO_ROOT/sesh/build_sesh_config.sh")"
  eval "$(sed -n '/^prepend_worktree_icon()/,/^}/p' "$REPO_ROOT/sesh/build_sesh_config.sh")"
}

# --- icon_for_file ---

@test "icon_for_file returns ICON_TOOL for tools.toml" {
  run icon_for_file "tools.toml"
  assert_success
  assert_output "$ICON_TOOL"
}

@test "icon_for_file returns ICON_CONFIG for config.toml" {
  run icon_for_file "config.toml"
  assert_success
  assert_output "$ICON_CONFIG"
}

@test "icon_for_file returns WORKTREE sentinel for worktrees.toml" {
  run icon_for_file "worktrees.toml"
  assert_success
  assert_output "WORKTREE"
}

@test "icon_for_file returns ICON_PROJECT for unknown file" {
  run icon_for_file "myapp.toml"
  assert_success
  assert_output "$ICON_PROJECT"
}

# --- prepend_icon ---

@test "prepend_icon prepends icon to name lines" {
  local tmpfile
  tmpfile="$(mktemp)"
  cat > "$tmpfile" <<'TOML'
[[session]]
name = "fastfetch"
path = "~/.config/fastfetch"
TOML
  run prepend_icon "$tmpfile" "$ICON_TOOL"
  assert_success
  assert_line --index 0 '[[session]]'
  assert_line --index 1 "name = \"$ICON_TOOL fastfetch\""
  assert_line --index 2 'path = "~/.config/fastfetch"'
  rm -f "$tmpfile"
}

@test "prepend_icon handles multiple entries" {
  local tmpfile
  tmpfile="$(mktemp)"
  cat > "$tmpfile" <<'TOML'
[[session]]
name = "alpha"

[[session]]
name = "beta"
TOML
  run prepend_icon "$tmpfile" "$ICON_PROJECT"
  assert_success
  assert_line --index 1 "name = \"$ICON_PROJECT alpha\""
  assert_line --index 3 "name = \"$ICON_PROJECT beta\""
  rm -f "$tmpfile"
}

@test "prepend_icon does not modify non-name lines" {
  local tmpfile
  tmpfile="$(mktemp)"
  cat > "$tmpfile" <<'TOML'
path = "/some/path"
startup_command = "echo hello"
TOML
  run prepend_icon "$tmpfile" "$ICON_TOOL"
  assert_success
  assert_line --index 0 'path = "/some/path"'
  assert_line --index 1 'startup_command = "echo hello"'
  rm -f "$tmpfile"
}

# --- prepend_worktree_icon ---

@test "prepend_worktree_icon uses ICON_WORKTREE for names with slash" {
  local tmpfile
  tmpfile="$(mktemp)"
  cat > "$tmpfile" <<'TOML'
[[session]]
name = "myproject/feature/auth"
TOML
  run prepend_worktree_icon "$tmpfile"
  assert_success
  assert_line --index 1 "name = \"$ICON_WORKTREE myproject/feature/auth\""
  rm -f "$tmpfile"
}

@test "prepend_worktree_icon uses ICON_WORKTREE_PROJECT for names without slash" {
  local tmpfile
  tmpfile="$(mktemp)"
  cat > "$tmpfile" <<'TOML'
[[session]]
name = "myproject"
TOML
  run prepend_worktree_icon "$tmpfile"
  assert_success
  assert_line --index 1 "name = \"$ICON_WORKTREE_PROJECT myproject\""
  rm -f "$tmpfile"
}
