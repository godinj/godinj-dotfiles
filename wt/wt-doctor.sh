#!/usr/bin/env bash
set -euo pipefail

# wt doctor — check bare repo layout and sesh config consistency.
# Report-only, non-destructive. Exits non-zero if issues found.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Allow env var overrides for testing; otherwise load from wt-helpers.sh
if [ -z "${WT_GIT_BASE:-}" ]; then
  source "$SCRIPT_DIR/wt-helpers.sh"
else
  WT_DOTFILES_DIR="${WT_DOTFILES_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"
  if [ -z "${MACHINE_DIR:-}" ]; then
    source "$WT_DOTFILES_DIR/machine.sh"
  fi
fi

# ── Output helpers (same style as install.sh) ────────────────────────────────

info()  { printf "\033[1;34m::\033[0m %s\n" "$*"; }
ok()    { printf "\033[1;32m✓\033[0m  %s\n" "$*"; }
warn()  { printf "\033[1;33m!\033[0m  %s\n" "$*"; }
err()   { printf "\033[1;31m✗\033[0m  %s\n" "$*"; }

ISSUES=0

# ── Check 1: Bare repo layout ───────────────────────────────────────────────

check_bare_repos() {
  info "Checking bare repo layout in $WT_GIT_BASE..."

  local found=0
  for repo_dir in "$WT_GIT_BASE"/*.git; do
    [ -d "$repo_dir" ] || continue
    found=1
    local name
    name="$(basename "$repo_dir")"

    # Regular clone masquerading as bare (has .git/ subdir)
    if [ -d "$repo_dir/.git" ]; then
      err "$name is a regular clone named *.git (has .git/ subdirectory)"
      ISSUES=$((ISSUES + 1))
      continue
    fi

    # Verify it's actually a bare repo
    if [ "$(git -C "$repo_dir" rev-parse --is-bare-repository 2>/dev/null)" != "true" ]; then
      warn "$name does not appear to be a bare repository"
      ISSUES=$((ISSUES + 1))
      continue
    fi

    # Check default branch worktree exists
    local default_branch
    default_branch="$(git -C "$repo_dir" symbolic-ref --short HEAD 2>/dev/null || echo "main")"
    local worktree_dir="$repo_dir/$default_branch"

    if [ ! -d "$worktree_dir" ]; then
      err "$name is missing default branch worktree: $default_branch/"
      ISSUES=$((ISSUES + 1))
    else
      ok "$name — $default_branch/ exists"
    fi
  done

  if [ "$found" -eq 0 ]; then
    warn "No *.git directories found in $WT_GIT_BASE"
  fi
}

# ── Check 2 & 3: Sesh path existence and convention ─────────────────────────

check_sesh_paths() {
  info "Checking sesh session paths..."

  local toml_dirs=("$WT_DOTFILES_DIR/sesh/sessions")
  if [ -d "$MACHINE_DIR/sesh/sessions" ]; then
    toml_dirs+=("$MACHINE_DIR/sesh/sessions")
  fi

  local found=0
  for dir in "${toml_dirs[@]}"; do
    for toml in "$dir"/*.toml; do
      [ -f "$toml" ] || continue
      local toml_label
      toml_label="$(basename "$dir" sessions)/$(basename "$toml")"

      while IFS= read -r raw_path; do
        found=1
        # Expand ~ to $HOME
        local expanded="${raw_path/#\~/$HOME}"

        # Check 2: path exists on disk
        if [ ! -d "$expanded" ]; then
          err "Path does not exist: $raw_path  ($toml_label)"
          ISSUES=$((ISSUES + 1))
          continue
        fi

        # Check 3: stale non-bare path convention
        # If path is ~/git/<name>/... and ~/git/<name>.git/ exists as bare repo
        if [[ "$raw_path" =~ ^~/git/([^/.]+)/(.*)$ ]]; then
          local project="${BASH_REMATCH[1]}"
          local bare_candidate="$WT_GIT_BASE/${project}.git"
          if [ -d "$bare_candidate" ] && [ ! -d "$bare_candidate/.git" ]; then
            warn "Stale non-bare path: $raw_path — bare repo exists at ${project}.git/  ($toml_label)"
            ISSUES=$((ISSUES + 1))
            continue
          fi
        fi

        ok "$raw_path"
      done < <(grep -oP '^\s*path\s*=\s*"\K[^"]+' "$toml")
    done
  done

  if [ "$found" -eq 0 ]; then
    warn "No sesh session paths found"
  fi
}

# ── Run checks ───────────────────────────────────────────────────────────────

echo ""
check_bare_repos
echo ""
check_sesh_paths
echo ""

# ── Summary ──────────────────────────────────────────────────────────────────

if [ "$ISSUES" -gt 0 ]; then
  err "Found $ISSUES issue(s)"
  exit 1
else
  ok "All checks passed"
fi
