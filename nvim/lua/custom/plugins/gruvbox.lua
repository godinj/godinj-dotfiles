-- Fallback colorscheme: only active when no machine_theme.lua exists
return {
  'https://gitlab.com/motaz-shokry/gruvbox.nvim',
  name = 'gruvbox',
  lazy = false,
  priority = 1000,
  cond = not vim.uv.fs_stat(vim.fn.stdpath('config') .. '/lua/custom/plugins/machine_theme.lua'),
  config = function()
    vim.cmd 'colorscheme gruvbox'
  end,
}
