#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── Helpers ──────────────────────────────────────────────────────────────────

info()  { printf "\033[1;34m::\033[0m %s\n" "$*"; }
ok()    { printf "\033[1;32m✓\033[0m  %s\n" "$*"; }
warn()  { printf "\033[1;33m!\033[0m  %s\n" "$*"; }
err()   { printf "\033[1;31m✗\033[0m  %s\n" "$*"; }

# ── Detect OS & package manager ─────────────────────────────────────────────

OS="$(uname -s)"
case "$OS" in
  Darwin) PKG=brew ;;
  Linux)
    if command -v apt-get &>/dev/null; then PKG=apt
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

# ── Step 2: Symlinks ──────────────────────────────────────────────────────

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
create_link "$DOTFILES_DIR/sesh/sesh.toml"     "$HOME/.config/sesh/sesh.toml"
create_link "$DOTFILES_DIR/.env.template"      "$HOME/.env.template"

echo ""

# ── Step 3: Install core dependencies ───────────────────────────────────────

install_pkg() {
  local name="$1"
  if command -v "$name" &>/dev/null; then
    ok "$name already installed"
    return
  fi

  local pkg_name="${2:-$name}"
  info "Installing $name..."
  case "$PKG" in
    brew) brew install "$pkg_name" ;;
    apt)  sudo apt-get install -y "$pkg_name" ;;
    dnf)  sudo dnf install -y "$pkg_name" ;;
  esac
}

info "Installing core dependencies..."

install_pkg zsh

# NVM + Node (needed before Neovim for plugin ecosystem)
if [ -d "$HOME/.nvm" ] || (command -v brew &>/dev/null && brew list nvm &>/dev/null 2>&1); then
  ok "NVM already installed"
else
  info "Installing NVM..."
  case "$PKG" in
    brew) brew install nvm && mkdir -p "$HOME/.nvm" ;;
    apt|dnf)
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

# Neovim — build from source
NEOVIM_SRC="$HOME/neovim"
if command -v nvim &>/dev/null; then
  ok "nvim already installed ($(nvim --version | head -1))"
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
install_pkg fzf
if [ "$PKG" = "apt" ]; then
  install_pkg fd fd-find
else
  install_pkg fd
fi
install_pkg bat
install_pkg rg ripgrep
install_pkg zoxide
install_pkg git
install_pkg make
install_pkg curl
install_pkg fastfetch

# sesh
if command -v sesh &>/dev/null; then
  ok "sesh already installed"
else
  info "Installing sesh..."
  case "$PKG" in
    brew)
      brew install joshmedeski/sesh/sesh
      ;;
    apt|dnf)
      if command -v go &>/dev/null; then
        go install github.com/joshmedeski/sesh@latest
      else
        warn "Go not found — install Go first, then run: go install github.com/joshmedeski/sesh@latest"
      fi
      ;;
  esac
fi

echo ""

# ── Step 4: Oh-My-Zsh ───────────────────────────────────────────────────────

if [ -d "$HOME/.oh-my-zsh" ]; then
  ok "Oh-My-Zsh already installed"
else
  info "Installing Oh-My-Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# ── Step 5: TPM (Tmux Plugin Manager) ───────────────────────────────────────

if [ -d "$HOME/.tmux/plugins/tpm" ]; then
  ok "TPM already installed"
else
  info "Installing TPM..."
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

# ── Step 6: Create .env from template ───────────────────────────────────────

if [ -f "$HOME/.env" ]; then
  ok ".env already exists"
else
  info "Creating .env from template..."
  cp "$DOTFILES_DIR/.env.template" "$HOME/.env"
  warn "Edit ~/.env to add your API keys"
fi

# ── Step 7: Optional — audio dev dependencies ───────────────────────────────

if [ "$PKG" = "brew" ]; then
  read -rp "Install audio dev dependencies (Ardour build libs)? [y/N] " audio_yn
  if [[ "$audio_yn" =~ ^[Yy]$ ]]; then
    info "Installing audio dev libs..."
    brew install glib glibmm libarchive liblo taglib vamp-plugin-sdk fftw pango gobject-introspection
    ok "Audio dev dependencies installed"
    info "Uncomment the audio-dev module line in zsh/.zshrc to activate"
  fi
fi

# ── Step 8: Optional — npm globals ──────────────────────────────────────────

read -rp "Install npm globals (mcp-hub)? [y/N] " npm_yn
if [[ "$npm_yn" =~ ^[Yy]$ ]]; then
  if command -v npm &>/dev/null; then
    npm install -g mcp-hub
    ok "mcp-hub installed"
  else
    warn "npm not found — install Node via nvm first, then run: npm install -g mcp-hub"
  fi
fi

echo ""

# ── Done ─────────────────────────────────────────────────────────────────────

info "Installation complete! Next steps:"
echo "  1. Open a new terminal or run: source ~/.zshrc"
echo "  2. Open tmux and press prefix + I to install tmux plugins"
echo "  3. Open nvim — plugins auto-install via lazy.nvim"
echo "  4. Edit ~/.env to add your API keys"
echo ""
