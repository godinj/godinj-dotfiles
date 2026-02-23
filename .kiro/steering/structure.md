---
inclusion: always
---

# Project Structure

## Directory layout

```
.
├── claude/commands/       # Claude Code slash commands (wt-new, wt-status, etc.)
├── drem-sx/               # Go CLI session picker
│   └── internal/
│       ├── config/        # Config loading, DOTFILES_DIR resolution
│       ├── icons/         # Icon constants and mapping
│       └── tree/          # Tree view formatting, fold state
├── git/                   # Git config templates
├── machines/              # Machine-specific overrides
│   ├── mba/               # macOS config (zsh, sesh, LaunchAgents)
│   ├── deb-lap/           # Debian laptop (systemd services, Sway)
│   ├── deb-desk/          # Debian desktop
│   ├── termux/            # Termux (Android)
│   └── wsl2/              # WSL2
├── nvim/                  # Neovim config (lazy.nvim, Lua)
├── sesh/sessions/         # Shared session TOML files
├── tests/                 # bats-core shell tests
│   └── libs/              # bats-core + helpers (git submodules)
├── tmux/                  # Tmux config and plugins
├── wt/                    # Worktree management scripts
└── zsh/                   # Shared shell config
```

## Bare repo worktree layout

All worktree-managed projects live under `~/git/` as bare repos:

```
~/git/project.git/              # bare repo
~/git/project.git/main/         # default branch worktree
~/git/project.git/feature/foo/  # feature branch worktree
```

## DOTFILES_DIR resolution

#[[file:drem-sx/internal/config/config.go]] resolves the dotfiles directory with fallback chain:

1. `$DOTFILES_DIR` env var — validated by checking for `machine.sh` marker
2. `~/tmux-config` symlink — follows to `$DOTFILES_DIR/tmux`, takes parent
3. Walk up from executable looking for `machine.sh`

The `~/tmux-config` symlink (created by #[[file:install.sh]]) is the critical fallback, making the picker immune to stale `$DOTFILES_DIR` values.

## Clipboard & file transfer tunnel architecture

```
mba → rsh host (-R 2224:…:2224 -R 2225:…:2225) → remote
```

- **Port 2224 (clipboard)**: remote sends via `clip()` → `nc 127.0.0.1 2224`; mba listens via LaunchAgent → `pbcopy`
- **Port 2225 (file transfer)**: remote sends via `send <file>` → `nc 127.0.0.1 2225`; mba parses filename from first line, writes to `~/Downloads`

The `rsh` function (defined in #[[file:machines/mba/zsh/machine.zsh]]) SSHs with `-t` and both reverse tunnels, injecting `clip` and `send` helpers into the remote bash session. No files are deployed to the remote host.
