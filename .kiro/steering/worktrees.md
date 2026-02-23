---
inclusion: fileMatch
fileMatch:
  - "wt/**"
---

# Worktree Conventions

## Branch naming

New worktree branches always get the `feature/` prefix. `wt new auth` creates branch `feature/auth`. The prefix is enforced by `wt_ensure_prefix()` in #[[file:wt/wt-helpers.sh]].

## Session naming

The `wt_session_name()` function in #[[file:wt/wt-helpers.sh]] produces tmux session names:

- `project` — default branch worktree (top-level project icon applied at runtime)
- `project/feature/name` — feature branch worktree
- `project/branch` — non-prefixed branch

The drem-sx tree picker groups feature worktrees under their parent project using icon-agnostic bare-name matching in #[[file:drem-sx/internal/tree/tree.go]].

## Tmux session layout

Every worktree session has a `code` window with two panes:
- Left (80%): Neovim editor
- Right (20%): Claude agent (`$WT_AGENT_CMD`, default `cld`)

Additional agents can be spawned into an `agents` window via `wt agent spawn`.

## Promoted sessions

Promoted worktree sessions are stored in `$MACHINE_DIR/sesh/sessions/worktrees.toml` (gitignored, machine-local) with **bare names** (no icon prefix). The `wt_bare_name()` helper returns the icon-free name for TOML storage; `wt_session_name()` returns the icon-prefixed name for tmux operations.

## Key scripts

- #[[file:wt/wt-new.sh]] — Create new worktree
- #[[file:wt/wt-rm.sh]] — Remove worktree and clean up session
- #[[file:wt/wt-helpers.sh]] — Shared helper functions (naming, prefix, bare-name)
- #[[file:wt/wt-agent.sh]] — Agent spawn/management
- #[[file:wt/wt-promote.sh]] — Promote worktree session to picker
