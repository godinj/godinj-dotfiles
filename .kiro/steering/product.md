---
inclusion: always
---

# Product Context

## What this project is

A multi-machine dotfiles repository that manages shell, editor, terminal multiplexer, and tooling configuration across heterogeneous platforms. Each machine gets a tailored environment built from shared defaults plus machine-specific overrides.

## Target platforms

- **mba** — macOS (Apple Silicon), primary development machine
- **deb-lap** — Debian laptop (Wayland/Sway)
- **deb-desk** — Debian desktop
- **termux** — Android terminal emulator
- **wsl2** — Windows Subsystem for Linux

## Key workflows

- **install.sh** — Bootstrap a new machine: detects platform, symlinks config, sets up tmux plugin manager
- **wt** — Worktree lifecycle management (new, rm, agent spawn, promote sessions)
- **drem-sx** — Go CLI session picker for tmux (icon-aware, tree view, fold/expand)
- **rsh** — Remote shell with clipboard and file transfer tunnels (mba-only)
- **switch-machine.sh** — Swap active machine profile by re-pointing `machines/current` symlink
