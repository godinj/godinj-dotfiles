# Agent Guidelines

## drem-sx session picker

`drem-sx` is the Go CLI that replaces the old `sesh` + bash scripts. Source is in `drem-sx/`, installed to `~/go/bin/drem-sx`.

### Session icons

Session names in source TOML files (`sesh/sessions/*.toml`, `machines/*/sesh/sessions/*.toml`) are stored **without** icon prefixes. Icons are applied at runtime by `drem-sx/internal/config/config.go` using icon constants from `drem-sx/internal/icons/icons.go`.

When editing source TOML session entries, write bare names (e.g. `name = "fastfetch"`, not `name = "fastfetch"` with an icon). The config loader maps each TOML filename to its icon category:
- `tools.toml` → Tool icon
- `config.toml` → Config icon
- `worktrees.toml` → Worktree or WorktreeProject based on `/` in name
- All other files → Project icon

### DOTFILES_DIR resolution

`drem-sx` resolves the dotfiles directory via `config.DotfilesDir()` with fallback chain:

1. `$DOTFILES_DIR` env var — **validated** by checking for `machine.sh` marker
2. `~/tmux-config` symlink — follows to `$DOTFILES_DIR/tmux`, takes parent
3. Walk up from executable looking for `machine.sh`

The `~/tmux-config` symlink (created by `install.sh`) is the critical fallback. It makes the picker immune to stale `$DOTFILES_DIR` values in the tmux server environment (e.g. from pruned worktrees that set `DOTFILES_DIR` before being deleted).

### Go tests

```bash
cd drem-sx && go test ./...    # all Go tests
go test ./internal/config/...  # single package
```

## nvim-treesitter: new API only

The lockfile (`nvim/lazy-lock.json`) pins nvim-treesitter to `branch = "main"` (the 2024 rewrite). The old `nvim-treesitter.configs` module **no longer exists**.

Correct config in `nvim/init.lua`:
```lua
config = function()
  require('nvim-treesitter').install { 'bash', 'go', 'lua', ... }
end,
```
Neovim 0.12+ auto-starts treesitter highlighting for installed parsers.

**Do NOT use any of these (old API):**
- `main = 'nvim-treesitter.configs'`
- `require('nvim-treesitter.configs').setup(opts)`
- `opts = { highlight = { enable = true }, indent = { enable = true } }`

There must be only ONE treesitter plugin spec, in `nvim/init.lua`. Do not create a second spec in `nvim/lua/custom/plugins/treesitter.lua` — it conflicts via lazy.nvim merging. If restoring nvim config from a backup, the treesitter section MUST be checked against this rule.

Filetype-specific fold/indent autocmds live in `nvim/lua/core/options.lua`, not in the treesitter plugin spec.

## Worktree conventions

### Bare repo layout

All worktree-managed projects live under `~/git/` as bare repos:

```
~/git/project.git/              # bare repo
~/git/project.git/main/         # default branch worktree
~/git/project.git/feature/foo/  # feature branch worktree
```

### Branch naming

New worktree branches always get the `feature/` prefix. `wt new auth` creates branch `feature/auth`. The prefix is enforced by `wt_ensure_prefix()` in `wt/wt-helpers.sh`.

### Session naming

The `wt_session_name()` function in `wt/wt-helpers.sh` produces:

- `󱁤 project` — default branch worktree (top-level project icon)
- `󰀜 project/feature/name` — feature branch worktree
- `󰀜 project/branch` — non-prefixed branch

The drem-sx tree picker groups `󰀜 project/…` under `󱁤 project` using icon-agnostic bare-name matching in `drem-sx/internal/tree/tree.go`.

### Tmux session layout

Every worktree session has a `code` window with two panes:
- Left (80%): Neovim editor
- Right (20%): Claude agent (`$WT_AGENT_CMD`, default `cld`)

Additional agents can be spawned into an `agents` window via `wt agent spawn`.

### Migrating existing repos

Conventional repos (non-bare, with a `.git/` directory) should be converted to the bare-repo layout using `wt migrate`. This preserves all local branches, stashes, and hooks by promoting the `.git/` directory in place rather than re-cloning.

```bash
wt migrate ~/git/myproject                          # basic migration
wt migrate ~/git/myproject --copy-untracked          # also copy untracked files
wt migrate ~/git/myproject --copy-untracked --remove  # and remove old dir
```

**Do NOT** manually rearrange `.git/` directories or use `git clone --bare` for migration — that loses local branches, stashes, and hooks. Always use `wt migrate`.

### Scripts and config

The `wt/` directory contains all worktree management scripts. Promoted worktree sessions are stored in `$MACHINE_DIR/sesh/sessions/worktrees.toml` (gitignored, machine-local) with bare names (no icon prefix) and loaded at runtime by `drem-sx`. The `wt_bare_name()` helper returns the icon-free name for TOML storage; `wt_session_name()` returns the icon-prefixed name for tmux operations.

## Unit tests

### Shell tests (bats-core)

**Framework:** [bats-core](https://github.com/bats-core/bats-core) with bats-support, bats-assert, and bats-file helpers, pinned as git submodules under `tests/libs/`.

**Running tests:**
```bash
./run_tests.sh                                              # all tests
./tests/libs/bats-core/bin/bats tests/wt/wt-helpers.bats   # single file
./run_tests.sh --verbose-run                                # verbose output
```

**Conventions:**
- Test files use `.bats` extension and mirror the source directory structure under `tests/`.
- All test files load `tests/test_helper.bash` which sets `DOTFILES_DIR` and loads bats helpers.
- Tests cover **pure functions only** — no tmux, no git operations, no network calls.
- `wt-helpers.sh` is sourced with `2>/dev/null || true` to suppress the `machine.sh` fallback warning.
- Test data uses inline heredocs, not fixture files.
- After submodule clone, run `git submodule update --init --recursive` if `tests/libs/` is empty.

### Go tests (drem-sx)

```bash
cd drem-sx && go test ./...
```

Tests cover config loading, icon mapping, session merging, tree formatting, fold state, and DOTFILES_DIR resolution.

## Clipboard & file transfer tunnel architecture

```
mba → rsh host (-R 2224:…:2224 -R 2225:…:2225) → remote
```

### Port 2224 — Clipboard
- **remote** (sender): `clip()` → `nc 127.0.0.1 2224`
- **mba** (listener): LaunchAgent → `nc -l 127.0.0.1 2224 | pbcopy`
- **deb-lap** (listener): systemd user service → `nc -l 127.0.0.1 2224 | wl-copy`
- **deb-desk** (sender): `clip()` / nvim yank → `nc -q 0 localhost 2224`

### Port 2225 — File transfer
- **remote** (sender): `send <file>` → basename + contents to `nc 127.0.0.1 2225`
- **mba** (listener): LaunchAgent → parses filename from first line, writes to `$MACHINE_RECEIVE_DIR` (default `~/Downloads`)

### `rsh` function (mba)
Defined in `machines/mba/zsh/machine.zsh`. SSHs with `-t` and both reverse tunnels, then injects `clip` and `send` helper functions into the remote bash session via `exec bash --rcfile <(...)`. No files are deployed to the remote host.

The deb-lap systemd service uses `WantedBy=graphical-session.target` (not `default.target`) so `wl-copy` has access to Wayland env vars (`WAYLAND_DISPLAY`, `XDG_RUNTIME_DIR`).
