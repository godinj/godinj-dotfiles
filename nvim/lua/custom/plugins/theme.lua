-- Machine theme dispatch: if a machine-specific theme exists, use it instead
local machine_theme = vim.fn.stdpath('config') .. '/lua/custom/plugins/machine_theme.lua'
if vim.uv.fs_stat(machine_theme) then
  return dofile(machine_theme)
end

return {
  'folke/tokyonight.nvim',
  priority = 1000,
  config = function()
    require('tokyonight').setup {
      styles = { comments = { italic = false } },
    }
    vim.cmd.colorscheme 'tokyonight-night'
  end,
}
