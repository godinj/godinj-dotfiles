# Amazon Linux 2 (al-dev) Setup Notes

Session date: 2026-04-02

## Problem

Amazon Linux 2 has glibc 2.26 and ships with tmux 1.8. Most modern CLI tools distribute binaries requiring glibc 2.28+ and the default yum repos don't carry tools like fd, bat, ripgrep, zoxide, btop, or fastfetch.

## Changes to `install.sh`

### 1. GitHub release installer for yum-only tools

Added `github_latest_version()` and `install_github_tar()` helper functions that auto-detect the latest release tag from the GitHub API and download musl static binaries. The yum case now installs these from GitHub releases instead of attempting `yum install`:

- `fd` — `sharkdp/fd` musl binary
- `bat` — `sharkdp/bat` musl binary
- `rg` — `BurntSushi/ripgrep` musl binary
- `btop` — `aristocratos/btop` musl binary (`.tbz` format)
- `zoxide` — installed via its official install script

Other package managers (`brew`, `apt`, `dnf`) continue using native packages.

### 2. Node.js glibc detection

Node 18+ requires glibc 2.28+. Added a glibc version check before installing Node via NVM:

- If glibc >= 2.28: installs latest LTS as before
- If glibc < 2.28: falls back to Node 16 (last compatible version)

Also fixed the node check to verify the binary actually runs (`node --version &>/dev/null`) instead of just checking if it exists — prevents false "already installed" when the binary exists but crashes with glibc errors.

### 3. fastfetch polyfilled build for yum

Replaced the `warn "fastfetch not in yum repos"` with an actual install using the `polyfilled` variant from GitHub releases, which bundles glibc compatibility shims for older systems.

## Changes to `machines/al-dev/tmux/machine.conf`

Added gruvbox tmux theme override:

```tmux
set -g @plugin 'egel/tmux-gruvbox'
set -g @tmux-gruvbox 'dark256'
```

This overrides the shared rose-pine theme from `theme.conf`. The rose-pine plugin directory (`~/.tmux/plugins/tmux`) was removed on the machine so gruvbox takes effect.

## Manual setup performed (not in install.sh)

These were done because `install.sh` didn't complete its full run on the first attempt.

### Symlinks created

| Source | Target |
|--------|--------|
| `zsh/.zshrc` | `~/.zshrc` |
| `git/.gitconfig` | `~/.gitconfig` |
| `nvim/` | `~/.config/nvim` |
| `alacritty/` | `~/.config/alacritty` |
| `tmux/` | `~/tmux-config` |
| `tmux/.tmux.conf` | `~/.tmux.conf` |
| `.env.template` | `~/.env.template` |
| `claude/commands` | `~/.claude/commands` |

### Neovim built from source

- Installed build deps: `ninja-build`, `cmake3`, `gcc`, `make`, `gettext`, `curl`
- Cloned and built Neovim from source → `nvim v0.13.0-dev` at `/usr/local/bin/nvim`
- Copied `machines/al-dev/nvim/theme.lua` → `nvim/lua/custom/plugins/machine_theme.lua`
- Fixed root ownership on `machine_theme.lua`

### tmux 3.5a built from source

- Old tmux 1.8 at `/usr/bin/tmux` was incompatible with the config
- Installed build deps: `libevent-devel`, `ncurses-devel`, `bison`, `byacc`
- Built tmux 3.5a from source → `/usr/local/bin/tmux`
- Had to kill old server process directly (`kill <pid>`) due to protocol version mismatch

### TPM installed

- Cloned `tmux-plugins/tpm` to `~/.tmux/plugins/tpm`
- Manually cloned `egel/tmux-gruvbox` to `~/.tmux/plugins/tmux-gruvbox`

### fzf installed from GitHub

- Cloned `junegunn/fzf` to `~/.fzf`
- Copied `fzf` and `fzf-tmux` to `/usr/local/bin/`

### zoxide installed from GitHub release

- Downloaded `zoxide-0.9.9-x86_64-unknown-linux-musl.tar.gz`
- Installed to `/usr/local/bin/zoxide`

### tree-sitter-cli built via cargo

- The npm and GitHub release binaries both require glibc 2.28+
- Installed Rust via rustup
- Installed `clang-devel` (provides `libclang.so` needed by bindgen)
- Built `tree-sitter-cli` v0.26.8 via `cargo install` with `LIBCLANG_PATH=/usr/lib64`
- Copied to `/usr/local/bin/tree-sitter`

### NVM + Node 16

- Installed NVM v0.40.1 via curl
- Installed Node 16.20.2 (last version compatible with glibc 2.26)

### fastfetch installed (polyfilled build)

- Used `fastfetch-linux-amd64-polyfilled` variant from GitHub releases
- Installed fastfetch 2.61.0 to `/usr/local/bin/fastfetch`

### drem-sx built

- Installed Go via `yum install golang`
- Built `drem-sx` from `drem-sx/` directory → `~/go/bin/drem-sx`

## Changes to `machines/al-dev/zsh/machine.zsh` (new file)

Created a gruvbox-inspired color override for the `rkj-repos` zsh prompt theme:

- Box/brackets: yellow (gruvbox gold)
- Username: green (gruvbox green)
- `@`: yellow
- Hostname: cyan (gruvbox aqua)
- Path: white (gruvbox fg)
- Date: magenta (gruvbox purple)
- Exit code: red (gruvbox red)
- Git branch: green
- Git status icons: cyan/yellow/red

Uses single quotes for `PROMPT` to defer `$fg` expansion to render time.

## Changes to `zsh/.zshrc`

Moved the `machine.zsh` source line from before `oh-my-zsh.sh` (line 35) to after it (line 102). Oh-My-Zsh applies the theme on load, so any PROMPT overrides set before it were being overwritten. The early source was removed entirely.
