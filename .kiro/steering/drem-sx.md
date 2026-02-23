---
inclusion: fileMatch
fileMatch:
  - "drem-sx/**"
---

# drem-sx Session Picker

`drem-sx` is the Go CLI that replaces the old `sesh` + bash scripts. Source is in `drem-sx/`, installed to `~/go/bin/drem-sx`.

## Icon mapping

Icons are applied at runtime by #[[file:drem-sx/internal/config/config.go]] using constants from #[[file:drem-sx/internal/icons/icons.go]]. The mapping is based on TOML filename:

| TOML file        | Icon category    |
|------------------|------------------|
| `tools.toml`     | Tool             |
| `config.toml`    | Config           |
| `worktrees.toml` | Worktree / WorktreeProject (based on `/` in name) |
| All other files  | Project          |

Source TOML files store **bare names only** — never include icon prefixes in session entries.

## DOTFILES_DIR fallback chain

#[[file:drem-sx/internal/config/config.go]] resolves `DotfilesDir()` via:

1. `$DOTFILES_DIR` env var — validated by checking for `machine.sh` marker
2. `~/tmux-config` symlink — follows to `$DOTFILES_DIR/tmux`, takes parent
3. Walk up from executable looking for `machine.sh`

## Key source files

- #[[file:drem-sx/internal/config/config.go]] — Config loading, session merging, DOTFILES_DIR resolution
- #[[file:drem-sx/internal/icons/icons.go]] — Icon constants and category mapping
- #[[file:drem-sx/internal/tree/tree.go]] — Tree view formatting, fold/expand state
- #[[file:drem-sx/cmd/root.go]] — CLI entry point

## Running tests

```bash
cd drem-sx && go test ./...       # all tests
go test ./internal/config/...     # single package
go test -v ./internal/tree/...    # verbose output for a package
```
