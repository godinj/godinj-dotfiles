# dotfiles

Personal development environment configuration for macOS, Linux, Termux/Android, and WSL2 — centered around a terminal-first workflow with Neovim, tmux, and zsh.

## Quick Start

```bash
git clone git@github.com:godinj/godinj-dotfiles.git ~/git/godinj-dotfiles
cd ~/git/godinj-dotfiles
bash install.sh
```

The installer is idempotent — safe to re-run at any time.

## Scripts

### install.sh

Main entry point. Backs up existing configs, prompts for a machine profile, creates symlinks, deploys machine-specific overrides, and installs all dependencies (zsh, neovim, tmux, fzf, ripgrep, sesh, lazygit, Go, nvm, etc.). Detects OS and package manager automatically.

```bash
bash install.sh
```

### switch-machine.sh

Switch between machine profiles after installation. Copies the selected profile's tmux, nvim, and sesh configs into place and rebuilds the sesh config.

```bash
bash switch-machine.sh        # interactive menu
bash switch-machine.sh mba    # switch directly to a profile
```

### backup.sh

Creates a timestamped backup of existing config files in `~/.dotfiles-backup/`. Called automatically by `install.sh` but can be run standalone.

```bash
bash backup.sh
```

### ssh-setup.sh

Sets up SSH for GitHub end-to-end: generates an ed25519 key, installs and authenticates with `gh`, and uploads the public key. Cross-platform (macOS, Linux, Termux).

```bash
bash ssh-setup.sh
```

### sesh/build_sesh_config.sh

Merges sesh configuration from multiple sources into `~/.config/sesh/sesh.toml`. Called by `install.sh` and `switch-machine.sh`. Sources are merged in order:

1. `sesh/base.toml` — sort order and base settings
2. `sesh/sessions/*.toml` — shared sessions (excludes `local.toml`)
3. `machines/<profile>/sesh/sessions/*.toml` — machine-specific sessions
4. `sesh/sessions/local.toml` — local overrides (gitignored)

```bash
bash sesh/build_sesh_config.sh
```

### machine.sh

Shared helper sourced by `install.sh`, `switch-machine.sh`, and `build_sesh_config.sh`. Reads `.machine` to resolve the active profile name and directory. Not meant to be run directly.

### tmux/scripts/sesh_picker.sh

Interactive tmux session picker using fzf. Provides keyboard shortcuts for filtering by session type (`Ctrl+T` tmux, `Ctrl+G` config, `Ctrl+X` zoxide, `Ctrl+F` find, `Ctrl+D` kill). Bound in the tmux config — not meant to be run directly.

## Machine Profiles

Machine-specific configs live under `machines/<name>/`. Each profile can override tmux config, nvim theme, and sesh sessions. The active profile is stored in `.machine` (gitignored).

Available profiles: `default`, `mba`, `wsl-sd`.

## Structure

```
godinj-dotfiles/
├── install.sh             # Main installer
├── backup.sh              # Config backup
├── switch-machine.sh      # Switch machine profiles
├── ssh-setup.sh           # GitHub SSH setup
├── machine.sh             # Machine profile helper (sourced)
├── .env.template          # API key template (copy to .env)
├── machines/              # Machine-specific overrides
│   ├── default/
│   ├── mba/
│   └── wsl-sd/
├── zsh/
│   ├── .zshrc
│   └── modules/
│       └── audio-dev.zsh
├── git/
│   └── .gitconfig
├── nvim/
│   ├── init.lua
│   └── lua/
├── tmux/
│   ├── .tmux.conf
│   ├── core.conf
│   ├── workflow.conf
│   ├── theme.conf
│   └── scripts/
└── sesh/
    ├── base.toml
    ├── build_sesh_config.sh
    └── sessions/
```

## Symlink Map

| Source (in repo)          | Target                    |
|---------------------------|---------------------------|
| `zsh/.zshrc`              | `~/.zshrc`                |
| `git/.gitconfig`          | `~/.gitconfig`            |
| `nvim/`                   | `~/.config/nvim`          |
| `tmux/`                   | `~/tmux-config`           |
| `tmux/.tmux.conf`         | `~/.tmux.conf`            |

## Shell (zsh)

Uses Oh-My-Zsh with the `rkj-repos` theme. Secrets are loaded from `~/.env` (gitignored).

Key integrations:
- **zoxide** for fast directory jumping
- **nvm** for Node.js version management (portable: brew on macOS, curl installer on Linux)
- **fzf** integration via tmux scripts
- **sesh** auto-launch on new terminal sessions

### Aliases

| Alias | Command |
|-------|---------|
| `dd` | SSH to remote server |
| `cl` | Launch Claude CLI |
| `tk` | `tmux kill-server` |
| `t` | `tmux` |
| `src` | `source ~/.zshrc` |
| `vrc` | Open `.zshrc` in Neovim |

### Optional Modules

Enable audio dev tooling by uncommenting the source line at the bottom of `zsh/.zshrc`:

```bash
source "$DOTFILES_DIR/zsh/modules/audio-dev.zsh"
```

## Git

Custom aliases for log visualization:

- `git st` — status
- `git history` — decorated graph log
- `git ht` — history trimmed to 30 commits
- `git recent` — last 15 commits from the past month
- `git dag` — DAG visualization

Uses `vimdiff` for diff/merge and `nvim` as the editor.

## Neovim

Built on [kickstart.nvim](https://github.com/nvim-kickstart/kickstart.nvim) with lazy.nvim.

### Swapping Themes

Edit `nvim/lua/custom/plugins/theme.lua` to change the colorscheme. The file is auto-loaded by `{ import = 'custom.plugins' }` in init.lua.

### Key Plugins

- **telescope.nvim** — fuzzy finder
- **neo-tree.nvim** — file explorer
- **blink.cmp** — completion engine
- **conform.nvim** — formatting
- **gitsigns.nvim** — inline git signs
- **treesitter** — syntax highlighting
- **avante.nvim** — AI assistant
- **mcphub.nvim** — MCP server integration
- **snacks.nvim** — dashboard, indent guides, notifier

## tmux

Prefix key: `C-Space`. Config is split into three sourced files for modularity.

### Swapping Themes

Edit `tmux/theme.conf` to change the tmux theme independently.

### Session Management

- `M-c` — fuzzy session picker via sesh + fzf
- `prefix + C` — create new session with name prompt
- `prefix + Space` — last active window
- `C-Space C-Space` — last active session
- `prefix + C-0..9` — switch to numbered session

### Pane/Window Operations

- `prefix + "` / `%` — split horizontal/vertical (preserves cwd)
- `prefix + j` / `J` — join pane from another window
- `prefix + (` / `)` — swap pane up/down
- `prefix + k` / `u` — even vertical/horizontal layout

### Plugins

- [tpm](https://github.com/tmux-plugins/tpm) — plugin manager
- [tmux-sensible](https://github.com/tmux-plugins/tmux-sensible) — sensible defaults
- [rose-pine/tmux](https://github.com/rose-pine/tmux) — theme (moon variant)

## Dependencies

**Required:**

- zsh + [Oh-My-Zsh](https://ohmyz.sh/)
- [Neovim](https://neovim.io/) (0.9+)
- [tmux](https://github.com/tmux/tmux)
- [fzf](https://github.com/junegunn/fzf)
- [fd](https://github.com/sharkdp/fd)
- [bat](https://github.com/sharkdp/bat)
- [ripgrep](https://github.com/BurntSushi/ripgrep)
- [zoxide](https://github.com/ajeetdsouza/zoxide)
- [sesh](https://github.com/joshmedeski/sesh)
- [nvm](https://github.com/nvm-sh/nvm)

All dependencies are installed automatically by `install.sh`.

**Optional:**

- [Ollama](https://ollama.com/) — local LLM for Avante
- Docker
- Python 3
- Audio dev libs (prompted during install on macOS)
