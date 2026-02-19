#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── Helpers ──────────────────────────────────────────────────────────────────

info()  { printf "\033[1;34m::\033[0m %s\n" "$*"; }
ok()    { printf "\033[1;32m✓\033[0m  %s\n" "$*"; }
warn()  { printf "\033[1;33m!\033[0m  %s\n" "$*"; }
err()   { printf "\033[1;31m✗\033[0m  %s\n" "$*"; }

render_template() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  envsubst < "$src" > "$dest"
  ok "Rendered $(basename "$dest")"
}

# ── Detect OS & package manager ─────────────────────────────────────────────

OS="$(uname -s)"
case "$OS" in
  Darwin) PKG=brew ;;
  Linux)
    if [ -n "${TERMUX_VERSION:-}" ]; then PKG=termux
    elif command -v apt-get &>/dev/null; then PKG=apt
    elif command -v dnf &>/dev/null;    then PKG=dnf
    else err "Unsupported Linux distro (no apt or dnf found)"; exit 1; fi
    ;;
  *) err "Unsupported OS: $OS"; exit 1 ;;
esac
info "Detected $OS with package manager: $PKG"

# ── Step 1: Backup existing configs ─────────────────────────────────────────

info "Running backup..."
bash "$DOTFILES_DIR/backup.sh"
echo ""

# ── Step 2: Machine profile ──────────────────────────────────────────────

source "$DOTFILES_DIR/machine.sh"

if [ -f "$MACHINE_FILE" ]; then
  info "Current machine profile: $MACHINE_NAME"
  read -rp "Keep this profile? [Y/n] " keep_yn
  if [[ "$keep_yn" =~ ^[Nn]$ ]]; then
    rm -f "$MACHINE_FILE"
  fi
fi

if [ ! -f "$MACHINE_FILE" ]; then
  info "Available machine profiles:"
  profiles=()
  for d in "$MACHINES_DIR"/*/; do
    [ -d "$d" ] || continue
    profiles+=("$(basename "$d")")
  done
  for i in "${!profiles[@]}"; do
    echo "  $((i+1))) ${profiles[$i]}"
  done
  while true; do
    read -rp "Select profile [1-${#profiles[@]}]: " choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#profiles[@]}" ]; then
      MACHINE_NAME="${profiles[$((choice-1))]}"
      break
    fi
    echo "  Invalid choice, try again."
  done
  echo "$MACHINE_NAME" > "$MACHINE_FILE"
  MACHINE_DIR="$MACHINES_DIR/$MACHINE_NAME"
  ok "Machine profile set to: $MACHINE_NAME"
fi

if [ -f "$MACHINE_DIR/vars.sh" ]; then
  source "$MACHINE_DIR/vars.sh"
  ok "Loaded vars from $MACHINE_NAME"
fi
echo ""

# ── Step 3: Symlinks ──────────────────────────────────────────────────────

create_link() {
  local src="$1"
  local dest="$2"

  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    ok "$(basename "$dest") already linked"
    return
  fi

  # Remove existing file/dir/symlink at destination
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    rm -rf "$dest"
  fi

  mkdir -p "$(dirname "$dest")"
  ln -sf "$src" "$dest"
  ok "Linked $dest -> $src"
}

info "Creating symlinks..."
create_link "$DOTFILES_DIR/zsh/.zshrc"        "$HOME/.zshrc"
create_link "$DOTFILES_DIR/git/.gitconfig"     "$HOME/.gitconfig"
create_link "$DOTFILES_DIR/nvim"               "$HOME/.config/nvim"
create_link "$DOTFILES_DIR/tmux"               "$HOME/tmux-config"
create_link "$DOTFILES_DIR/tmux/.tmux.conf"    "$HOME/.tmux.conf"
create_link "$DOTFILES_DIR/.env.template"      "$HOME/.env.template"

# Deploy machine-specific files
info "Deploying machine profile: $MACHINE_NAME"
ln -sf "$MACHINE_DIR/tmux/machine.conf" "$DOTFILES_DIR/tmux/machine.conf"
ok "Symlinked tmux/machine.conf → $MACHINE_NAME"
if [ -f "$MACHINE_DIR/zsh/machine.zsh" ]; then
  ln -sf "$MACHINE_DIR/zsh/machine.zsh" "$DOTFILES_DIR/zsh/machine.zsh"
  ok "Symlinked zsh/machine.zsh → $MACHINE_NAME"
else
  rm -f "$DOTFILES_DIR/zsh/machine.zsh"
fi
cp "$MACHINE_DIR/nvim/theme.lua" "$DOTFILES_DIR/nvim/lua/custom/plugins/machine_theme.lua"
ok "Copied nvim machine_theme.lua"
bash "$DOTFILES_DIR/sesh/build_sesh_config.sh"
ok "Built sesh.toml from modular configs"

# Darwin-specific: clipboard listener LaunchAgent
if [ "$OS" = "Darwin" ]; then
  info "Setting up clipboard listener LaunchAgent..."
  mkdir -p "$HOME/.local/bin"
  cp "$MACHINE_DIR/scripts/clipboard-listener.sh" "$HOME/.local/bin/clipboard-listener.sh"
  chmod +x "$HOME/.local/bin/clipboard-listener.sh"
  ok "Copied clipboard-listener.sh → ~/.local/bin/"

  PLIST="$HOME/Library/LaunchAgents/com.godinj.clipboard-listener.plist"
  render_template "$MACHINE_DIR/scripts/com.godinj.clipboard-listener.plist.tpl" "$PLIST"

  GUI_DOMAIN="gui/$(id -u)"
  launchctl bootout "$GUI_DOMAIN/com.godinj.clipboard-listener" 2>/dev/null || true
  launchctl bootstrap "$GUI_DOMAIN" "$PLIST"
  ok "Clipboard listener LaunchAgent loaded"
fi

# Linux-specific: clipboard listener systemd user service
if [ "$OS" = "Linux" ] && [ -f "$MACHINE_DIR/scripts/clipboard-listener.sh" ]; then
  info "Setting up clipboard listener systemd service..."
  mkdir -p "$HOME/.local/bin"
  cp "$MACHINE_DIR/scripts/clipboard-listener.sh" "$HOME/.local/bin/clipboard-listener.sh"
  chmod +x "$HOME/.local/bin/clipboard-listener.sh"
  ok "Copied clipboard-listener.sh → ~/.local/bin/"

  mkdir -p "$HOME/.config/systemd/user"
  cp "$MACHINE_DIR/scripts/clipboard-listener.service" "$HOME/.config/systemd/user/clipboard-listener.service"
  systemctl --user daemon-reload
  systemctl --user enable --now clipboard-listener.service
  ok "Clipboard listener systemd service enabled"
fi

echo ""

# ── Step 4: Install core dependencies ───────────────────────────────────────

install_pkg() {
  local name="$1"
  if command -v "$name" &>/dev/null; then
    ok "$name already installed"
    return
  fi

  local pkg_name="${2:-$name}"
  info "Installing $name..."
  case "$PKG" in
    brew)   brew install "$pkg_name" ;;
    apt)    sudo apt-get install -y "$pkg_name" ;;
    dnf)    sudo dnf install -y "$pkg_name" ;;
    termux) pkg install -y "$pkg_name" ;;
  esac
}

info "Installing core dependencies..."

install_pkg zsh
install_pkg unzip

# NVM + Node (needed before Neovim for plugin ecosystem)
if [ -d "$HOME/.nvm" ] || (command -v brew &>/dev/null && brew list nvm &>/dev/null 2>&1); then
  ok "NVM already installed"
else
  info "Installing NVM..."
  case "$PKG" in
    brew) brew install nvm && mkdir -p "$HOME/.nvm" ;;
    apt|dnf|termux)
      curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
      ;;
  esac
fi

# Source NVM for current shell
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
if [ "$PKG" = "brew" ]; then
  [ -s "$(brew --prefix)/opt/nvm/nvm.sh" ] && . "$(brew --prefix)/opt/nvm/nvm.sh"
fi

if command -v node &>/dev/null; then
  ok "node already installed ($(node --version))"
else
  if command -v nvm &>/dev/null; then
    info "Installing Node LTS via NVM..."
    nvm install --lts
    ok "Node installed ($(node --version))"
  else
    warn "NVM not available — install Node manually before opening Neovim"
  fi
fi

# tree-sitter-cli (needed by nvim-treesitter to compile parsers from grammar)
if command -v tree-sitter &>/dev/null; then
  ok "tree-sitter-cli already installed"
elif command -v npm &>/dev/null; then
  info "Installing tree-sitter-cli..."
  npm install -g tree-sitter-cli
  ok "tree-sitter-cli installed"
else
  warn "npm not found — skipping tree-sitter-cli install"
fi

# Neovim — use pkg on Termux, build from source elsewhere
NEOVIM_SRC="$HOME/neovim"
if command -v nvim &>/dev/null; then
  ok "nvim already installed ($(nvim --version | head -1))"
elif [ "$PKG" = "termux" ]; then
  info "Installing Neovim via pkg..."
  pkg install -y neovim
  ok "Neovim installed ($(nvim --version | head -1))"
else
  info "Installing Neovim build dependencies..."
  case "$PKG" in
    brew) brew install ninja cmake gettext curl ;;
    apt)  sudo apt-get install -y ninja-build gettext cmake curl build-essential ;;
    dnf)  sudo dnf install -y ninja-build cmake gcc make gettext curl glibc-gconv-extra ;;
  esac

  if [ -d "$NEOVIM_SRC" ]; then
    info "Updating existing Neovim source..."
    git -C "$NEOVIM_SRC" pull
  else
    info "Cloning Neovim from source..."
    git clone https://github.com/neovim/neovim.git "$NEOVIM_SRC"
  fi

  info "Building Neovim (RelWithDebInfo)..."
  make -C "$NEOVIM_SRC" CMAKE_BUILD_TYPE=RelWithDebInfo
  info "Installing Neovim..."
  sudo make -C "$NEOVIM_SRC" install
  ok "Neovim installed ($(nvim --version | head -1))"
fi

install_pkg tmux
# fzf + fzf-tmux — Termux has a recent version; apt version is too old, install from GitHub
if [ "$PKG" = "termux" ]; then
  install_pkg fzf
else
  if [ -d "$HOME/.fzf" ]; then
    git -C "$HOME/.fzf" pull
  else
    git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
  fi

  if command -v fzf &>/dev/null && fzf --version 2>&1 | grep -qv debian; then
    ok "fzf already installed ($(fzf --version))"
  else
    info "Installing fzf from GitHub..."
    "$HOME/.fzf/install" --bin
    sudo cp "$HOME/.fzf/bin/fzf" /usr/local/bin/fzf
    ok "fzf installed ($(fzf --version))"
  fi

  if command -v fzf-tmux &>/dev/null; then
    ok "fzf-tmux already installed"
  else
    info "Installing fzf-tmux..."
    sudo cp "$HOME/.fzf/bin/fzf-tmux" /usr/local/bin/fzf-tmux
    ok "fzf-tmux installed"
  fi
fi
case "$PKG" in
  apt) install_pkg fd fd-find ;;
  *)   install_pkg fd ;;
esac
install_pkg bat
install_pkg rg ripgrep
install_pkg zoxide
install_pkg git
install_pkg make
install_pkg curl
# fastfetch — not in default apt repos
if command -v fastfetch &>/dev/null; then
  ok "fastfetch already installed"
else
  info "Installing fastfetch..."
  case "$PKG" in
    brew)   brew install fastfetch ;;
    apt)
      sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch
      sudo apt-get update
      sudo apt-get install -y fastfetch
      ;;
    dnf)    sudo dnf install -y fastfetch ;;
    termux) pkg install -y fastfetch ;;
  esac
fi

install_pkg go golang

# sesh (via Go)
if command -v sesh &>/dev/null; then
  ok "sesh already installed"
else
  info "Installing sesh via Go..."
  go install github.com/joshmedeski/sesh@latest
fi

# lazygit (via Go)
if command -v lazygit &>/dev/null; then
  ok "lazygit already installed"
else
  info "Installing lazygit via Go..."
  go install github.com/jesseduffield/lazygit@latest
fi

# JetBrainsMono Nerd Font
if [ "$PKG" = "termux" ]; then
  if [ -f "$HOME/.termux/font.ttf" ]; then
    ok "Termux font already installed"
  else
    info "Installing JetBrainsMono Nerd Font for Termux..."
    mkdir -p "$HOME/.termux"
    curl -fsSL -o "$HOME/.termux/font.ttf" \
      https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/JetBrainsMono/Ligatures/Regular/JetBrainsMonoNerdFont-Regular.ttf
    termux-reload-settings
    ok "JetBrainsMono Nerd Font installed (restart Termux if needed)"
  fi
elif [ "$PKG" != "termux" ]; then
  if fc-list 2>/dev/null | grep -qi "JetBrainsMono" || ([ "$PKG" = "brew" ] && brew list --cask font-jetbrains-mono-nerd-font &>/dev/null 2>&1); then
    ok "JetBrainsMono Nerd Font already installed"
  else
    info "Installing JetBrainsMono Nerd Font..."
    case "$PKG" in
      brew)
        brew install --cask font-jetbrains-mono-nerd-font
        ;;
      apt|dnf)
        FONT_DIR="$HOME/.local/share/fonts/JetBrainsMono"
        mkdir -p "$FONT_DIR"
        FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"
        curl -fsSL "$FONT_URL" | tar -xJ -C "$FONT_DIR"
        fc-cache -fv "$FONT_DIR"
        ;;
    esac
    ok "JetBrainsMono Nerd Font installed"
  fi

  # Install fonts on Windows side when running under WSL
  if grep -qi microsoft /proc/version 2>/dev/null; then
    WIN_LOCALAPPDATA="$(powershell.exe -NoProfile -Command '[Environment]::GetFolderPath("LocalApplicationData")' 2>/dev/null | tr -d '\r')"
    WIN_FONT_DIR="$WIN_LOCALAPPDATA\\Microsoft\\Windows\\Fonts"
    LINUX_WIN_FONT_DIR="$(wslpath "$WIN_FONT_DIR")"
    LINUX_FONT_SRC="$HOME/.local/share/fonts/JetBrainsMono"

    if [ -d "$LINUX_WIN_FONT_DIR" ] && ls "$LINUX_WIN_FONT_DIR"/JetBrains*.ttf &>/dev/null; then
      ok "JetBrainsMono fonts already installed on Windows"
    elif [ -d "$LINUX_FONT_SRC" ]; then
      info "Copying JetBrainsMono fonts to Windows user font directory..."
      mkdir -p "$LINUX_WIN_FONT_DIR"
      cp "$LINUX_FONT_SRC"/*.ttf "$LINUX_WIN_FONT_DIR"/

      info "Registering fonts in Windows registry..."
      for ttf in "$LINUX_WIN_FONT_DIR"/*.ttf; do
        FILENAME="$(basename "$ttf")"
        FONTNAME="$(echo "$FILENAME" | sed 's/\.ttf$//' | sed 's/NerdFont/Nerd Font/' | sed 's/-/ /g') (TrueType)"
        WIN_FONT_PATH="$WIN_FONT_DIR\\$FILENAME"
        powershell.exe -NoProfile -Command \
          "New-ItemProperty -Path 'HKCU:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Fonts' -Name '$FONTNAME' -Value '$WIN_FONT_PATH' -PropertyType String -Force" \
          >/dev/null 2>&1
      done
      ok "JetBrainsMono fonts installed and registered on Windows"
    fi
  fi
fi

echo ""

# ── Step 5: Oh-My-Zsh ───────────────────────────────────────────────────────

if [ -d "$HOME/.oh-my-zsh" ]; then
  ok "Oh-My-Zsh already installed"
else
  info "Installing Oh-My-Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# ── Step 6: TPM (Tmux Plugin Manager) ───────────────────────────────────────

if [ -d "$HOME/.tmux/plugins/tpm" ]; then
  ok "TPM already installed"
else
  info "Installing TPM..."
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

# ── Step 7: Create .env from template ───────────────────────────────────────

if [ -f "$HOME/.env" ]; then
  ok ".env already exists"
else
  info "Creating .env from template..."
  cp "$DOTFILES_DIR/.env.template" "$HOME/.env"
  warn "Edit ~/.env to add your API keys"
fi


# ── Done ─────────────────────────────────────────────────────────────────────

info "Installation complete! Next steps:"
echo "  1. Open a new terminal or run: source ~/.zshrc"
echo "  2. Open tmux and press prefix + I to install tmux plugins"
echo "  3. Open nvim — plugins auto-install via lazy.nvim"
echo "  4. Edit ~/.env to add your API keys"
echo ""
