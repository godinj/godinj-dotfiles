#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE="$DOTFILES_DIR/opencode/opencode.json.tpl"
DEST="$HOME/.config/opencode/opencode.json"
PLUGIN="@guard22/opencode-multi-auth-codex@1.4.3"
AUTH_FILE="$HOME/.codex/auth.json"
MULTI_AUTH_STORE="$HOME/.config/opencode-multi-auth/accounts.json"
OPENCODE_AUTH="$HOME/.local/share/opencode/auth.json"

info()  { printf "\033[1;34m::\033[0m %s\n" "$*"; }
ok()    { printf "\033[1;32m✓\033[0m  %s\n" "$*"; }
warn()  { printf "\033[1;33m!\033[0m  %s\n" "$*"; }
err()   { printf "\033[1;31m✗\033[0m  %s\n" "$*"; }

backup_existing_config() {
  if [ ! -f "$DEST" ]; then
    return
  fi

  local stamp backup
  stamp="$(date +%Y%m%dT%H%M%S)"
  backup="$DEST.bak.$stamp-codex-subscription"
  cp "$DEST" "$backup"
  ok "Backed up existing opencode.json to $backup"
}

render_config() {
  if [ ! -f "$TEMPLATE" ]; then
    err "Template not found: $TEMPLATE"
    exit 1
  fi

  mkdir -p "$(dirname "$DEST")"
  sed -e "s|\${HOME}|$HOME|g" -e "s|\${MACHINE_RECEIVE_DIR}|${MACHINE_RECEIVE_DIR:-}|g" "$TEMPLATE" > "$DEST"
  ok "Rendered $DEST"
}

install_plugin() {
  if ! command -v opencode >/dev/null 2>&1; then
    warn "opencode is not on PATH; config was rendered, but plugin install was skipped"
    warn "After installing OpenCode, run: opencode plugin \"$PLUGIN\" --global --force"
    return
  fi

  opencode plugin "$PLUGIN" --global --force
  ok "Installed OpenCode plugin $PLUGIN"
}

check_codex_auth() {
  if [ -r "$AUTH_FILE" ]; then
    ok "Codex auth file is readable at $AUTH_FILE"
    return 0
  fi

  warn "Codex auth file not found at $AUTH_FILE"
  warn "Run: codex login"
  return 1
}

sync_codex_auth() {
  OPENCODE_MULTI_AUTH_CODEX_AUTH_FILE="$AUTH_FILE" \
  OPENCODE_MULTI_AUTH_STORE_FILE="$MULTI_AUTH_STORE" \
  OPENCODE_AUTH_FILE="$OPENCODE_AUTH" \
  node <<'NODE'
const fs = require('fs');
const os = require('os');
const path = require('path');

const authPath = process.env.OPENCODE_MULTI_AUTH_CODEX_AUTH_FILE || path.join(os.homedir(), '.codex', 'auth.json');
const storePath = process.env.OPENCODE_MULTI_AUTH_STORE_FILE || path.join(os.homedir(), '.config', 'opencode-multi-auth', 'accounts.json');
const opencodeAuthPath = process.env.OPENCODE_AUTH_FILE || path.join(os.homedir(), '.local', 'share', 'opencode', 'auth.json');
const now = Date.now();

function decodeJWT(token) {
  try {
    const parts = String(token || '').split('.');
    if (parts.length !== 3) return null;
    const payload = parts[1].replace(/-/g, '+').replace(/_/g, '/');
    const padded = payload.padEnd(payload.length + ((4 - (payload.length % 4)) % 4), '=');
    return JSON.parse(Buffer.from(padded, 'base64').toString('utf8'));
  } catch {
    return null;
  }
}

function ensureDir(dir, mode = 0o700) {
  fs.mkdirSync(dir, { recursive: true, mode });
}

function readJSON(file, fallback) {
  try {
    return JSON.parse(fs.readFileSync(file, 'utf8'));
  } catch {
    return fallback;
  }
}

function backupFile(file) {
  if (!fs.existsSync(file)) return;
  const stamp = new Date().toISOString().replace(/[-:]/g, '').replace(/\..*$/, '').replace('T', 'T');
  fs.copyFileSync(file, `${file}.bak.${stamp}-codex-subscription`);
}

function writeJSON(file, value, mode = 0o600) {
  ensureDir(path.dirname(file));
  backupFile(file);
  fs.writeFileSync(file, JSON.stringify(value, null, 2));
  fs.chmodSync(file, mode);
}

function aliasFrom(email, accountId) {
  const raw = (email && email.split('@')[0]) || (accountId && accountId.slice(0, 8)) || 'codex';
  return raw.replace(/[^A-Za-z0-9._-]/g, '-').replace(/^-+|-+$/g, '') || 'codex';
}

const codexAuth = readJSON(authPath, null);
const tokens = codexAuth && typeof codexAuth.tokens === 'object' ? codexAuth.tokens : codexAuth;
const accessToken = tokens && (tokens.access_token || tokens.accessToken || tokens.access);
const refreshToken = tokens && (tokens.refresh_token || tokens.refreshToken || tokens.refresh);
const idToken = tokens && (tokens.id_token || tokens.idToken || tokens.id);

if (!accessToken || !refreshToken) {
  console.error(`${authPath} is missing access/refresh tokens; run codex login`);
  process.exit(1);
}

const accessClaims = decodeJWT(accessToken);
const idClaims = idToken ? decodeJWT(idToken) : null;
const authClaims = (accessClaims && accessClaims['https://api.openai.com/auth']) || {};
const idAuthClaims = (idClaims && idClaims['https://api.openai.com/auth']) || {};
const profile = (idClaims && idClaims['https://api.openai.com/profile']) || {};
const email = profile.email || idClaims?.email || accessClaims?.email;
const accountId = tokens.account_id || tokens.accountId || authClaims.chatgpt_account_id || idAuthClaims.chatgpt_account_id;
const accountUserId = authClaims.chatgpt_account_user_id || idAuthClaims.chatgpt_account_user_id;
const userId = authClaims.user_id || authClaims.chatgpt_user_id || idAuthClaims.user_id || idAuthClaims.chatgpt_user_id;
const planType = authClaims.chatgpt_plan_type || idAuthClaims.chatgpt_plan_type;
const expiresAt = typeof accessClaims?.exp === 'number' ? accessClaims.exp * 1000 : now + 30 * 60 * 1000;
const alias = aliasFrom(email, accountId);

const store = readJSON(storePath, {
  version: 2,
  accounts: {},
  activeAlias: null,
  rotationIndex: 0,
  lastRotation: now,
  rotationStrategy: 'round-robin',
  settings: { rotationStrategy: 'round-robin' }
});

store.version = 2;
store.accounts = store.accounts && typeof store.accounts === 'object' ? store.accounts : {};
const account = {
  ...(store.accounts[alias] || {}),
  alias,
  accessToken,
  refreshToken,
  idToken,
  accountId,
  accountUserId,
  userId,
  planType,
  expiresAt,
  email,
  lastRefresh: codexAuth.last_refresh || codexAuth.lastRefresh,
  lastSeenAt: now,
  source: 'codex',
  usageCount: store.accounts[alias]?.usageCount || 0,
  enabled: true
};
delete account.authInvalid;
delete account.authInvalidatedAt;
delete account.limitError;
delete account.lastLimitErrorAt;
delete account.rateLimitedUntil;
store.accounts[alias] = account;
store.activeAlias = alias;
store.rotationIndex = typeof store.rotationIndex === 'number' ? store.rotationIndex : 0;
store.lastRotation = typeof store.lastRotation === 'number' ? store.lastRotation : now;
store.rotationStrategy = store.rotationStrategy || 'round-robin';
store.settings = store.settings || { rotationStrategy: store.rotationStrategy };
writeJSON(storePath, store);

const opencodeAuth = readJSON(opencodeAuthPath, {});
opencodeAuth.openai = {
  type: 'oauth',
  access: accessToken,
  refresh: refreshToken,
  expires: expiresAt
};
writeJSON(opencodeAuthPath, opencodeAuth);

console.log(`Synced Codex OAuth into OpenCode multi-auth alias=${alias}`);
NODE
  ok "Synced Codex auth into OpenCode auth stores"
}

main() {
  info "Configuring OpenCode to use Codex subscription auth"
  backup_existing_config
  render_config
  install_plugin
  if check_codex_auth; then
    sync_codex_auth
  fi
}

main "$@"
