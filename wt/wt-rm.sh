#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/wt-helpers.sh"

usage() {
  echo "Usage: wt rm <branch>" >&2
  exit 1
}

[ $# -lt 1 ] && usage

branch="$(wt_ensure_prefix "$1")"

bare_root="$(wt_find_bare_root)" || {
  echo "Error: not inside a git worktree or bare repo" >&2
  exit 1
}

project="$(wt_project_name "$bare_root")"
worktree_dir="$bare_root/$branch"

if [ ! -d "$worktree_dir" ]; then
  echo "Error: worktree '$worktree_dir' does not exist" >&2
  exit 1
fi

# Prevent removing the default branch worktree
default_branch="$(git -C "$bare_root" symbolic-ref --short HEAD 2>/dev/null || echo main)"
if [ "$branch" = "$default_branch" ]; then
  echo "Error: cannot remove the default branch worktree ('$default_branch')" >&2
  exit 1
fi

# Determine session and bare names
session_name="$(wt_session_name "$project" "$branch")"
bare_name="$(wt_bare_name "$project" "$branch")"

# Kill tmux session if active
if wt_session_exists "$session_name"; then
  echo "Killing session '$session_name'..."
  tmux kill-session -t "=$session_name"
fi

# Deinit submodules if present (git refuses to remove worktrees with submodules)
if [ -f "$worktree_dir/.gitmodules" ]; then
  echo "Deinitializing submodules..."
  git -C "$worktree_dir" submodule deinit --all -f
fi

# Clean up per-worktree submodule git dirs (worktrees/<name>/modules/)
wt_entry_name="$(basename "$worktree_dir")"
wt_modules_dir="$bare_root/worktrees/$wt_entry_name/modules"
if [ -d "$wt_modules_dir" ]; then
  echo "Cleaning up submodule metadata ($wt_entry_name/modules/)..."
  rm -rf "$wt_modules_dir"
fi

# Warn if this is the last worktree with the patched JUCE commit
if [ -d "$worktree_dir/libs/JUCE" ]; then
  juce_patched_commit=""
  # Read JUCE_PATCHED_COMMIT from bootstrap.sh if it exists
  if [ -f "$worktree_dir/scripts/bootstrap.sh" ]; then
    juce_patched_commit="$(grep -oP 'JUCE_PATCHED_COMMIT="\K[^"]+' "$worktree_dir/scripts/bootstrap.sh" 2>/dev/null || true)"
  fi

  if [ -n "$juce_patched_commit" ] && \
     git -C "$worktree_dir/libs/JUCE" cat-file -e "$juce_patched_commit" 2>/dev/null; then
    # This worktree has the patched commit — check if any sibling also has it
    has_sibling=false
    for sibling in "$bare_root"/*/libs/JUCE; do
      [ -d "$sibling" ] || continue
      [ "$sibling" = "$worktree_dir/libs/JUCE" ] && continue
      if git -C "$sibling" cat-file -e "$juce_patched_commit" 2>/dev/null; then
        has_sibling=true
        break
      fi
    done

    if [ "$has_sibling" = false ]; then
      echo ""
      echo "Warning: this is the last worktree with the patched JUCE commit ($juce_patched_commit)."
      echo "Other worktrees will need to apply patches from scripts/juce-patches/ on next bootstrap."
      echo ""
    fi
  fi
fi

# Remove worktree
echo "Removing worktree '$branch'..."
if ! git -C "$bare_root" worktree remove "$worktree_dir" 2>/dev/null; then
  # Fallback: manual removal + prune (handles stubborn submodule metadata)
  rm -rf "$worktree_dir"
  git -C "$bare_root" worktree prune
fi

# Clean worktrees.toml if entry exists
if [ -f "$WT_WORKTREES_TOML" ]; then
  # Remove the [[session]] block matching this session name
  if grep -q "name = \"$bare_name\"" "$WT_WORKTREES_TOML" 2>/dev/null; then
    echo "Removing entry from worktrees.toml..."
    # Use awk to remove the matching [[session]] block
    awk -v name="$bare_name" '
      BEGIN { skip=0 }
      /^\[\[session\]\]/ {
        block = $0
        skip = 0
        next_is_block = 1
        next
      }
      next_is_block {
        block = block "\n" $0
        if ($0 ~ "name = \"" name "\"") {
          skip = 1
        }
        next_is_block = 0
        if (skip) next
        printf "%s\n", block
        next
      }
      skip && /^$/ { skip = 0; next }
      skip && /^\[\[/ { skip = 0 }
      !skip { print }
    ' "$WT_WORKTREES_TOML" > "$WT_WORKTREES_TOML.tmp"
    mv "$WT_WORKTREES_TOML.tmp" "$WT_WORKTREES_TOML"
    echo "Removed from sesh config."
  fi
fi

# Ask about branch deletion
read -rp "Delete branch '$branch'? [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
  git -C "$bare_root" branch -d "$branch" 2>/dev/null || \
    git -C "$bare_root" branch -D "$branch"
  echo "Branch '$branch' deleted."
fi

echo "Done."
