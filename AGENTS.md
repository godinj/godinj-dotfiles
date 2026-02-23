# Dotfiles — Multi-Machine Configuration Manager

Cross-platform dotfiles for macOS (mba), Debian laptop/desktop, Termux, and WSL2.
Managed via bare-repo worktrees under `~/git/`.

## Key directories

- `wt/` — Worktree management scripts (bash)
- `drem-sx/` — Go CLI session picker (replaces sesh + bash scripts)
- `nvim/` — Neovim 0.12+ config (Lua, lazy.nvim)
- `tmux/` — Tmux config and plugins
- `zsh/` — Shell config, sourced per-machine
- `machines/` — Machine-specific overrides (mba, deb-lap, deb-desk, termux, wsl2)
- `sesh/sessions/` — Shared session TOML files (bare names, no icon prefixes)
- `tests/` — bats-core shell tests + Go tests in `drem-sx/`

## Critical conventions

1. **TOML session names** are stored without icon prefixes — icons are applied at runtime by `drem-sx`
2. **nvim-treesitter** uses the new API only (`require('nvim-treesitter').install{...}`) — no legacy `configs.setup()`
3. **Worktree branches** always get the `feature/` prefix via `wt new`
4. **Tests**: `./run_tests.sh` (shell) and `cd drem-sx && go test ./...` (Go)

## Agent-specific config

- **Claude Code**: `CLAUDE.md` + `claude/commands/`
- **Amazon Kiro**: `.kiro/steering/` + `.kiro/agents/`
