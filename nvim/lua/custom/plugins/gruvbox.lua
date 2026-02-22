-- Fallback colorscheme: only active when no machine_theme.lua exists.
-- Returns an empty table when machine_theme.lua is present so lazy.nvim
-- has nothing to merge (cond would poison the merged spec).
if vim.uv.fs_stat(vim.fn.stdpath('config') .. '/lua/custom/plugins/machine_theme.lua') then
  return {}
end

return {
  'https://gitlab.com/motaz-shokry/gruvbox.nvim',
  name = 'gruvbox',
  lazy = false,
  priority = 1000,
  config = function()
    vim.cmd 'colorscheme gruvbox'
  end,
}
