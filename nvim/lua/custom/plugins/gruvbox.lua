-- lua/plugins/gruvbox.lua
return {
  'https://gitlab.com/motaz-shokry/gruvbox.nvim',
  name = 'gruvbox',
  lazy = false,
  priority = 1000,
  config = function()
    vim.cmd 'colorscheme gruvbox'
  end,
}
