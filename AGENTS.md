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

## Clipboard tunnel architecture

```
deb-lap → SSH (-R 2224:localhost:2224) → deb-desk
```
- **deb-desk** (sender): `clip()` / nvim yank → `nc -q 0 localhost 2224`
- **deb-lap** (listener): systemd user service → `nc -l 127.0.0.1 2224 | wl-copy`
- **mba** (listener): LaunchAgent → `nc -l 127.0.0.1 2224 | pbcopy`

The deb-lap systemd service uses `WantedBy=graphical-session.target` (not `default.target`) so `wl-copy` has access to Wayland env vars (`WAYLAND_DISPLAY`, `XDG_RUNTIME_DIR`).
