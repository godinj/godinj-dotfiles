# dotfiles

Personal development environment configuration for macOS, Linux, Termux/Android, and WSL2 — centered around a terminal-first workflow with Neovim, tmux, and zsh.

## Quick Start

```bash
# One-liner (clones as bare repo + worktrees, then runs install.sh)
bash <(curl -fsSL https://raw.githubusercontent.com/godinj/godinj-dotfiles/master/bootstrap.sh)

# Or step by step
git clone --bare git@github.com:godinj/godinj-dotfiles.git ~/git/godinj-dotfiles.git
bash ~/git/godinj-dotfiles.git/master/bootstrap.sh
```

This follows the bare-repo-with-worktrees convention used by `wt` for all projects:

```
~/git/godinj-dotfiles.git/              # bare repo
~/git/godinj-dotfiles.git/master/       # default branch worktree
~/git/godinj-dotfiles.git/feature/foo/  # feature branch worktree
```

The bootstrap script and installer are both idempotent — safe to re-run at any time.

## Scripts

### install.sh

Main entry point. Backs up existing configs, prompts for a machine profile, creates symlinks, deploys machine-specific overrides (tmux, nvim theme, sesh configs, LaunchAgents on macOS), and installs all dependencies. Detects OS and package manager automatically. Supports template rendering via `envsubst` for machine-specific plist files.

OpenCode is configured from `opencode/opencode.json.tpl`, rendered to `~/.config/opencode/opencode.json` with `${HOME}` expanded. The config uses the pinned `@guard22/opencode-multi-auth-codex@1.4.3` plugin so OpenCode can use the operator's Codex subscription OAuth state. Run `codex login` on each machine; the auth file stays local at `~/.codex/auth.json` and is not stored in dotfiles.

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

### run_tests.sh

Discovers and runs all bats-core unit tests. Passes through any flags (e.g. `--verbose-run`). See [Unit Tests](#unit-tests) for details.

```bash
bash run_tests.sh
```

### sesh/build_sesh_config.sh

Merges sesh configuration from multiple sources into `~/.config/sesh/sesh.toml`. Called by `install.sh` and `switch-machine.sh`. Prepends icons from `sesh/icons.sh` to session names at build time based on source file (e.g. `tools.toml` gets the tool icon, `worktrees.toml` gets the worktree icon). Sources are merged in order:

1. `sesh/base.toml` — sort order and base settings
2. `sesh/sessions/*.toml` — shared sessions (excludes `local.toml`)
3. `machines/<profile>/sesh/sessions/worktrees.toml` — promoted worktree sessions
4. `machines/<profile>/sesh/sessions/*.toml` — machine-specific sessions
5. `sesh/sessions/local.toml` — local overrides (gitignored)

```bash
bash sesh/build_sesh_config.sh
```

### sesh/new_session.sh

Interactive script to add a new project session. Prompts for a session name, path (defaults to `~/git/<name>/`), and startup command (defaults to `nvim`). Appends a `[[session]]` entry to the machine-specific `projects.toml`, creates the directory on disk if needed, and rebuilds `sesh.toml`.

```bash
bash sesh/new_session.sh
```

### machine.sh

Shared helper sourced by `install.sh`, `switch-machine.sh`, and `build_sesh_config.sh`. Reads `.machine` to resolve the active profile name and directory. Not meant to be run directly.

### tmux/scripts/sesh_picker.sh

Interactive tmux session picker using fzf. Provides keyboard shortcuts for filtering by session type (`Ctrl+A` all, `Ctrl+T` tmux, `Ctrl+G` config, `Ctrl+X` zoxide, `Ctrl+F` find, `Ctrl+D` kill). Displays worktree sessions in a tree view (feature branches grouped under their project) via `sesh/sesh_tree_list.sh`. Auto-creates missing directories when selecting a path. Sources machine-specific aesthetics from `machines/<profile>/sesh/picker.sh` (popup size, colors, border label). Bound in the tmux config — not meant to be run directly.

## Worktree Management (`wt`)

The `wt` command manages git worktrees paired with tmux sessions and Claude Code agent panes. It enables parallel feature development where each branch gets its own directory, editor, and AI agent.

### Bare Repo Layout

All worktree-managed projects live under `~/git/` as bare repos:

```
~/git/project.git/              # bare repo (shared git objects)
~/git/project.git/main/         # default branch worktree
~/git/project.git/feature/foo/  # feature branch worktree
```

### Subcommands

| Command | Description |
|---------|-------------|
| `wt init <repo-url>` | Clone a repo as a bare repo with an initial worktree and tmux session |
| `wt new <branch> [base]` | Create a feature branch worktree + tmux session (auto-prefixes `feature/`) |
| `wt list` | List worktrees with session status and agent count |
| `wt rm <branch>` | Remove a worktree, kill its session, and clean promoted config |
| `wt promote` | Add the current session to persistent sesh config |
| `wt agent spawn` | Spawn an additional agent pane |
| `wt agent kill` | Kill the last agent pane |
| `wt agent list` | List agent panes in the current session |
| `wt help` | Show usage |

### Session Layout

Every worktree tmux session has a `code` window with two panes by default:
- Left (80%): Neovim editor
- Right (20%): Claude Code agent (`$WT_AGENT_CMD`, default `cld`)

Additional agents can be spawned into an `agents` window via `wt agent spawn`.

### Per-Project Configuration (`.wt.env`)

Place a `.wt.env` file in the bare repo root to customize the pane layout per project:

```bash
WT_PANE_0="nvim:70%"       # first pane: command and width
WT_PANE_1="aider:30%"      # second pane
WT_AGENT_CMD="aider"       # command for spawned agent panes
```

### Promoted Sessions

`wt promote` writes the current worktree session to `machines/<profile>/sesh/sessions/worktrees.toml` (machine-local, gitignored) so it appears in the sesh picker across terminal restarts. Session names are stored without icon prefixes — icons are prepended at build time.

## Clipboard & File Transfer

SSH reverse tunnels provide clipboard and file transfer from remote hosts back to the local machine.

### Architecture

```
local machine ── rsh host (-R 2224:…:2224 -R 2225:…:2225) ──▸ remote
```

- **Port 2224 (clipboard):** remote `clip()` pipes to `nc 127.0.0.1 2224`; local listener feeds `pbcopy` (macOS) or `wl-copy` (Linux/Wayland)
- **Port 2225 (file transfer):** remote `send <file>` streams basename + contents to `nc 127.0.0.1 2225`; local listener writes to `$MACHINE_RECEIVE_DIR` (default `~/Downloads`)

### `rsh` Function (macOS)

Defined in `machines/mba/zsh/machine.zsh`. SSHs with `-t` and both reverse tunnels, then injects the `clip` and `send` helper functions into the remote bash session via `exec bash --rcfile <(...)`. No files are deployed to the remote host.

### Local `clip()` Function

The shell also provides a local `clip()` function (in `.zshrc`) that auto-detects the right clipboard provider: `pbcopy` on macOS, `wl-copy` on local Linux, or OSC 52 escape sequences over SSH.

### Listeners

- **macOS:** LaunchAgent services (`com.godinj.clipboard-listener`, `com.godinj.file-receive-listener`) deployed from plist templates during `install.sh`
- **Linux (Wayland):** systemd user service with `WantedBy=graphical-session.target` so `wl-copy` has access to Wayland env vars

## Machine Profiles

Machine-specific configs live under `machines/<name>/`. Each profile can override tmux config, nvim theme, sesh sessions, and shell settings. The active profile is stored in `.machine` (gitignored).

Available profiles: `deb-desk`, `deb-lap`, `mba`, `wsl-sd`.

Each profile includes:
- `vars.sh` — environment variables (username, SSH key, receive directory)
- `tmux/machine.conf` — tmux overrides (prefix key, colors, keybindings, theme plugin)
- `nvim/theme.lua` — Neovim colorscheme plugin spec
- `sesh/sessions/*.toml` — project sessions
- `sesh/picker.sh` — fzf picker appearance (popup size, colors, border label)
- `zsh/machine.zsh` — shell overrides (zsh theme, machine-specific aliases) *(optional)*
- `scripts/` — machine-specific scripts (e.g. clipboard listeners on macOS) *(optional)*

### Themes by Profile

| Profile | Neovim | tmux |
|---------|--------|------|
| `mba` | gruvbox | rose-pine (moon) |
| `deb-desk` | gruvbox | rose-pine (moon) |
| `deb-lap` | kanagawa (wave) | gruvbox |
| `wsl-sd` | tokyonight (night) | rose-pine (moon) |

## Unit Tests

Uses [bats-core](https://github.com/bats-core/bats-core) with bats-support, bats-assert, and bats-file helpers, pinned as git submodules under `tests/libs/`.

```bash
./run_tests.sh                                              # all tests
./tests/libs/bats-core/bin/bats tests/wt/wt-helpers.bats   # single file
./run_tests.sh --verbose-run                                # verbose output
```

Tests cover pure functions only — no tmux, git, or network calls. Test files mirror the source directory structure under `tests/`:

- `tests/machine.bats` — machine profile resolution
- `tests/wt/wt-helpers.bats` — worktree helper functions (`wt_ensure_prefix`, `wt_project_name`, `wt_session_name`, `wt_bare_name`)
- `tests/sesh/icons.bats` — icon constant definitions
- `tests/sesh/build_sesh_config.bats` — sesh config build functions (`icon_for_file`, `prepend_icon`, `prepend_worktree_icon`)
- `tests/sesh/sesh_tree_list.bats` — tree view grouping logic

## Structure

```
godinj-dotfiles/
├── install.sh             # Main installer
├── backup.sh              # Config backup
├── switch-machine.sh      # Switch machine profiles
├── ssh-setup.sh           # GitHub SSH setup
├── run_tests.sh           # Run bats-core unit tests
├── machine.sh             # Machine profile helper (sourced)
├── CLAUDE.md              # Agent guidelines
├── .env.template          # API key template (copy to .env)
├── machines/              # Machine-specific overrides
│   ├── deb-desk/
│   ├── deb-lap/
│   ├── mba/
│   └── wsl-sd/
├── zsh/
│   └── .zshrc
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
├── sesh/
│   ├── base.toml
│   ├── icons.sh           # Central icon definitions
│   ├── build_sesh_config.sh
│   ├── sesh_tree_list.sh  # Tree view for worktree sessions
│   ├── new_session.sh
│   └── sessions/
├── wt/                    # Worktree + agent session management
│   ├── wt.sh              # Main entry point (subcommand router)
│   ├── wt-helpers.sh      # Shared helpers and config loading
│   ├── wt-init.sh         # Clone bare repo + initial worktree
│   ├── wt-new.sh          # Create feature branch worktree
│   ├── wt-list.sh         # List worktrees with status
│   ├── wt-rm.sh           # Remove worktree and clean up
│   ├── wt-agent.sh        # Spawn/kill/list agent panes
│   ├── wt-promote.sh      # Promote session to sesh config
│   └── wt-connect.sh      # Startup script for promoted sessions
└── tests/                 # bats-core unit tests
    ├── test_helper.bash
    ├── machine.bats
    ├── sesh/
    └── wt/
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

Uses Oh-My-Zsh with the `rkj-repos` theme (overridable per machine via `zsh/machine.zsh`). Secrets are loaded from `~/.env` (gitignored).

Key integrations:
- **zoxide** for fast directory jumping
- **nvm** for Node.js version management (portable: brew on macOS, curl installer on Linux)
- **fzf** integration via tmux scripts
- **sesh** auto-launch on new terminal sessions
- **clip()** function for cross-platform clipboard (pbcopy / wl-copy / OSC 52)

### Aliases

| Alias | Command |
|-------|---------|
| `dd` | SSH to remote server (key and options from machine profile) |
| `cl` | `claude` |
| `cld` | `claude --dangerously-skip-permissions` |
| `tk` | `tmux kill-server` |
| `t` | Launch sesh fastfetch session |
| `src` | `source ~/.zshrc` |
| `vrc` | Open `.zshrc` in Neovim |
| `cns` | Create new sesh session (`new_session.sh`) |
| `bsc` | Rebuild sesh config (`build_sesh_config.sh`) |
| `wt` | Worktree manager (`wt.sh`) |

## Git

Custom aliases for log visualization:

- `git st` — status
- `git history` — decorated graph log
- `git ht` — history trimmed to 30 commits
- `git recent` — last 15 commits from the past month
- `git dag` — DAG visualization

Uses `vimdiff` for diff/merge and `nvim` as the editor.

## Neovim

Built on [kickstart.nvim](https://github.com/nvim-kickstart/kickstart.nvim) with lazy.nvim. Requires Neovim 0.12+.

### Swapping Themes

Themes are set per machine profile in `machines/<profile>/nvim/theme.lua`. The active profile's theme is copied to `nvim/lua/custom/plugins/machine_theme.lua` during install. Available themes: gruvbox, kanagawa, tokyonight (see [Themes by Profile](#themes-by-profile)).

### Key Plugins

- **telescope.nvim** — fuzzy finder
- **neo-tree.nvim** — file explorer
- **blink.cmp** — completion engine
- **conform.nvim** — formatting
- **gitsigns.nvim** — inline git signs
- **treesitter** — syntax highlighting (new main-branch API, auto-highlights installed parsers)
- **snacks.nvim** — dashboard, indent guides, notifier
- **bufferline.nvim** — buffer tabs
- **lualine.nvim** — statusline
- **harpoon** — quick file navigation
- **render-markdown.nvim** — markdown rendering
- **nvim-jdtls** — Java LSP support

## tmux

Prefix key: `C-Space` (overridable per machine via `machine.conf`). Mouse mode is enabled for scrolling and pane interaction. Config is split into sourced files for modularity, with machine-specific overrides symlinked from the active profile.

### Swapping Themes

Edit `tmux/theme.conf` to change the tmux theme independently. Machine profiles can also override tmux settings (prefix key, colors, theme plugin) via `machines/<profile>/tmux/machine.conf`.

### Session Management

- `M-g` — fuzzy session picker via sesh + fzf (overridable per machine, e.g. `M-c`)
- `M-Space` — toggle last session
- `prefix + C` — create new session with name prompt
- `prefix + Space` — last active window
- `prefix + C-0..9` — switch to numbered session

### Worktree Agent Management

- `prefix + a` — spawn a new agent pane (`wt agent spawn`)
- `prefix + A` — kill the last agent pane (`wt agent kill`)

### Pane/Window Operations

- `prefix + "` / `%` — split horizontal/vertical (preserves cwd)
- `prefix + j` / `J` — join pane from another window
- `prefix + (` / `)` — swap pane up/down
- `prefix + k` / `u` — even vertical/horizontal layout

### Plugins

- [tpm](https://github.com/tmux-plugins/tpm) — plugin manager
- [tmux-sensible](https://github.com/tmux-plugins/tmux-sensible) — sensible defaults
- [rose-pine/tmux](https://github.com/rose-pine/tmux) — theme (moon variant, overridable per machine)

## Dependencies

**Required:**

- zsh + [Oh-My-Zsh](https://ohmyz.sh/)
- [Neovim](https://neovim.io/) (0.12+)
- [tmux](https://github.com/tmux/tmux)
- [fzf](https://github.com/junegunn/fzf)
- [fd](https://github.com/sharkdp/fd)
- [bat](https://github.com/sharkdp/bat)
- [ripgrep](https://github.com/BurntSushi/ripgrep)
- [zoxide](https://github.com/ajeetdsouza/zoxide)
- [sesh](https://github.com/joshmedeski/sesh)
- [lazygit](https://github.com/jesseduffield/lazygit)
- [nvm](https://github.com/nvm-sh/nvm) + Node.js
- [Go](https://go.dev/)
- [tree-sitter-cli](https://github.com/tree-sitter/tree-sitter) (installed via npm)

All dependencies are installed automatically by `install.sh`.

**Optional:**

- Docker
- Python 3
