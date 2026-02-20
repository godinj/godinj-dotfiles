# Agent Guidelines

## Sesh session names

Session names in `sesh/sessions/*.toml` and `machines/*/sesh/sessions/*.toml` begin with a Nerd Font icon (e.g. ` `, `󱘖 `, `󰰸 `). Always preserve these icons exactly as they appear. Never strip, replace, or omit them when editing or generating session entries.

## nvim-treesitter: new API only

The lockfile (`nvim/lazy-lock.json`) pins nvim-treesitter to `branch = "main"` (the 2024 rewrite). The old `nvim-treesitter.configs` module **no longer exists**.

Correct config in `nvim/init.lua`:
```lua
config = function()
  require('nvim-treesitter').install { 'bash', 'go', 'lua', ... }
end,
```
Neovim 0.12+ auto-starts treesitter highlighting for installed parsers.

**Do NOT use any of these (old API):**
- `main = 'nvim-treesitter.configs'`
- `require('nvim-treesitter.configs').setup(opts)`
- `opts = { highlight = { enable = true }, indent = { enable = true } }`

There must be only ONE treesitter plugin spec, in `nvim/init.lua`. Do not create a second spec in `nvim/lua/custom/plugins/treesitter.lua` — it conflicts via lazy.nvim merging. If restoring nvim config from a backup, the treesitter section MUST be checked against this rule.

Filetype-specific fold/indent autocmds live in `nvim/lua/core/options.lua`, not in the treesitter plugin spec.

## Clipboard & file transfer tunnel architecture

```
mba → rsh host (-R 2224:…:2224 -R 2225:…:2225) → remote
```

### Port 2224 — Clipboard
- **remote** (sender): `clip()` → `nc 127.0.0.1 2224`
- **mba** (listener): LaunchAgent → `nc -l 127.0.0.1 2224 | pbcopy`
- **deb-lap** (listener): systemd user service → `nc -l 127.0.0.1 2224 | wl-copy`
- **deb-desk** (sender): `clip()` / nvim yank → `nc -q 0 localhost 2224`

### Port 2225 — File transfer
- **remote** (sender): `send <file>` → basename + contents to `nc 127.0.0.1 2225`
- **mba** (listener): LaunchAgent → parses filename from first line, writes to `$MACHINE_RECEIVE_DIR` (default `~/Downloads`)

### `rsh` function (mba)
Defined in `machines/mba/zsh/machine.zsh`. SSHs with `-t` and both reverse tunnels, then injects `clip` and `send` helper functions into the remote bash session via `exec bash --rcfile <(...)`. No files are deployed to the remote host.

The deb-lap systemd service uses `WantedBy=graphical-session.target` (not `default.target`) so `wl-copy` has access to Wayland env vars (`WAYLAND_DISPLAY`, `XDG_RUNTIME_DIR`).
