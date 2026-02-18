#!/usr/bin/env bash
set -euo pipefail

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
    if [ -n "${TERMUX_VERSION:-}" ]; then PKG=termux
    elif command -v apt-get &>/dev/null; then PKG=apt
    elif command -v dnf &>/dev/null;    then PKG=dnf
    else err "Unsupported Linux distro (no apt or dnf found)"; exit 1; fi
    ;;
  *) err "Unsupported OS: $OS"; exit 1 ;;
esac
info "Detected $OS with package manager: $PKG"

# ── Step 1: Detect email ────────────────────────────────────────────────────

EMAIL="$(git config --global user.email 2>/dev/null || true)"
if [ -z "$EMAIL" ]; then
  read -rp "Enter your email for the SSH key: " EMAIL
  if [ -z "$EMAIL" ]; then
    err "Email is required"; exit 1
  fi
fi
ok "Using email: $EMAIL"

# ── Step 2: Generate SSH key ────────────────────────────────────────────────

KEY_PATH="$HOME/.ssh/id_ed25519"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [ -f "$KEY_PATH" ]; then
  warn "SSH key already exists at $KEY_PATH"
  read -rp "Overwrite? [y/N] " overwrite_yn
  if [[ "$overwrite_yn" =~ ^[Yy]$ ]]; then
    info "Generating new SSH key..."
    ssh-keygen -t ed25519 -C "$EMAIL" -f "$KEY_PATH" -N ""
    ok "SSH key generated at $KEY_PATH"
  else
    ok "Keeping existing SSH key"
  fi
else
  info "Generating SSH key..."
  ssh-keygen -t ed25519 -C "$EMAIL" -f "$KEY_PATH" -N ""
  ok "SSH key generated at $KEY_PATH"
fi

chmod 600 "$KEY_PATH"
chmod 644 "$KEY_PATH.pub"

# ── Step 3: Start ssh-agent ─────────────────────────────────────────────────

info "Starting ssh-agent..."
eval "$(ssh-agent -s)" > /dev/null
ssh-add "$KEY_PATH"
ok "Key added to ssh-agent"

# ── Step 4: Configure ~/.ssh/config ─────────────────────────────────────────

SSH_CONFIG="$HOME/.ssh/config"
GITHUB_BLOCK="Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes"

if [ -f "$SSH_CONFIG" ] && grep -q "Host github.com" "$SSH_CONFIG"; then
  ok "GitHub SSH config already present"
else
  info "Adding GitHub config to $SSH_CONFIG..."
  {
    [ -f "$SSH_CONFIG" ] && [ -s "$SSH_CONFIG" ] && echo ""
    echo "$GITHUB_BLOCK"
  } >> "$SSH_CONFIG"
  chmod 600 "$SSH_CONFIG"
  ok "GitHub SSH config added"
fi

# ── Step 5: Install gh CLI ──────────────────────────────────────────────────

if command -v gh &>/dev/null; then
  ok "gh already installed"
else
  info "Installing gh CLI..."
  case "$PKG" in
    brew) brew install gh ;;
    apt)
      sudo mkdir -p /etc/apt/keyrings
      curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
      sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | sudo tee /etc/apt/sources.list.d/github-cli-stable.list > /dev/null
      sudo apt-get update
      sudo apt-get install -y gh
      ;;
    dnf) sudo dnf install -y gh ;;
    termux) pkg install -y gh ;;
  esac
  ok "gh installed"
fi

# ── Step 6: Authenticate with GitHub ────────────────────────────────────────

if gh auth status &>/dev/null; then
  ok "Already authenticated with GitHub"
else
  info "Authenticating with GitHub (device code flow)..."
  info "You'll be given a code to enter at https://github.com/login/device"
  gh auth login -p ssh -h github.com -s admin:public_key
fi

# ── Step 7: Upload public key ───────────────────────────────────────────────

# Ensure we have the admin:public_key scope (may be missing from earlier auth)
if ! gh ssh-key list &>/dev/null; then
  info "Requesting admin:public_key scope..."
  gh auth refresh -h github.com -s admin:public_key
fi

KEY_TITLE="$(hostname) $(date +%Y-%m-%d)"
PUB_KEY="$(cat "$KEY_PATH.pub")"

if gh ssh-key list 2>/dev/null | grep -qF "${PUB_KEY##* }"; then
  ok "SSH key already uploaded to GitHub"
else
  info "Uploading SSH key to GitHub..."
  gh ssh-key add "$KEY_PATH.pub" --title "$KEY_TITLE"
  ok "SSH key uploaded with title: $KEY_TITLE"
fi

# ── Step 8: Verify ──────────────────────────────────────────────────────────

info "Verifying GitHub SSH connection..."
ssh_output="$(ssh -T git@github.com 2>&1 || true)"
if echo "$ssh_output" | grep -q "successfully authenticated"; then
  ok "SSH connection to GitHub verified"
else
  warn "Could not verify SSH connection — try: ssh -T git@github.com"
fi

echo ""
info "SSH setup complete!"
