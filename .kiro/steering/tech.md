---
inclusion: always
---

# Technology & Rules

## Languages and tools

- **Bash/Zsh** — Shell scripts (`wt/`, `zsh/`, `machines/`)
- **Go** — `drem-sx` session picker CLI (`drem-sx/`)
- **Lua** — Neovim configuration (`nvim/`)
- **TOML** — Session definitions (`sesh/sessions/`, `machines/*/sesh/sessions/`)
- **tmux** — Terminal multiplexer config (`tmux/`)
- **bats-core** — Shell unit testing framework (`tests/`)

## Critical rules

### nvim-treesitter: new API only

The lockfile pins nvim-treesitter to `branch = "main"` (2024 rewrite). Neovim 0.12+ auto-starts highlighting.

Correct usage in #[[file:nvim/init.lua]]:
```lua
config = function()
  require('nvim-treesitter').install { 'bash', 'go', 'lua', ... }
end,
```

**Never use** `require('nvim-treesitter.configs').setup(...)` or `main = 'nvim-treesitter.configs'` — the old module no longer exists. Only one treesitter spec allowed, in `nvim/init.lua`.

### TOML session names: bare names only

Session names in source TOML files are stored **without** icon prefixes. Icons are applied at runtime by `drem-sx` based on the TOML filename. See #[[file:drem-sx/internal/icons/icons.go]] for icon constants.

### Test conventions

Shell tests (bats-core):
```bash
./run_tests.sh                    # all shell tests
./tests/libs/bats-core/bin/bats tests/wt/wt-helpers.bats  # single file
```

Go tests:
```bash
cd drem-sx && go test ./...       # all Go tests
go test ./internal/config/...     # single package
```

Tests cover pure functions only — no tmux, no git operations, no network calls.
