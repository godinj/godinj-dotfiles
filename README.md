# dotfiles

Personal development environment configuration for macOS + Linux, centered around a terminal-first workflow with Neovim, tmux, and zsh.

## Quick Start

```bash
git clone https://github.com/godinj/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash install.sh
```

The installer is idempotent — safe to re-run at any time.

## Structure

```
godinj-dotfiles/
├── .gitignore
├── .env.template          # API key template (copy to .env)
├── backup.sh              # Back up existing configs
├── install.sh             # Idempotent installer
├── README.md
├── zsh/
│   ├── .zshrc             # Shell config (symlinked to ~/.zshrc)
│   └── modules/
│       └── audio-dev.zsh  # Optional audio dev PKG_CONFIG_PATHs
├── git/
│   └── .gitconfig         # Git config (symlinked to ~/.gitconfig)
├── nvim/                  # Neovim config (symlinked to ~/.config/nvim)
│   ├── init.lua
│   └── lua/
│       ├── core/
│       │   ├── options.lua
│       │   └── keymaps.lua
│       ├── plugins/
│       └── custom/plugins/
│           ├── theme.lua  # Colorscheme (swappable)
│           ├── avante.lua
│           ├── mcphub.lua
│           └── snacks.lua
├── tmux/                  # tmux config (symlinked to ~/tmux-config)
│   ├── .tmux.conf         # Thin loader (also symlinked to ~/.tmux.conf)
│   ├── core.conf          # Prefix, splits, nav, vi mode
│   ├── workflow.conf      # Sesh, join, resize, session switching
│   ├── theme.conf         # Rose-pine, status colors, plugins
│   └── scripts/           # Helper scripts for multi-pane workflows
└── sesh/
    └── sesh.toml          # Named session definitions
```

## Symlink Map

| Source (in repo)          | Target                    |
|---------------------------|---------------------------|
| `zsh/.zshrc`              | `~/.zshrc`                |
| `git/.gitconfig`          | `~/.gitconfig`            |
| `nvim/`                   | `~/.config/nvim`          |
| `tmux/`                   | `~/tmux-config`           |
| `tmux/.tmux.conf`         | `~/.tmux.conf`            |
| `sesh/sesh.toml`          | `~/.config/sesh/sesh.toml`|

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
