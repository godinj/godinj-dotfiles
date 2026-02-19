return {
  'nvim-treesitter/nvim-treesitter',
  build = ':TSUpdate',
  opts = {
    ensure_installed = { 'go', 'lua', 'java', 'json', 'python', 'vim', 'vimdoc' },
    highlight = { enable = true },
    indent = { enable = true },
  },
  -- Use 'config' instead of 'main' for the setup function
  config = function(_, opts)
    vim.api.nvim_create_autocmd('FileType', {
      pattern = { 'python', 'java' },
      callback = function()
        vim.opt_local.foldmethod = 'expr'
        vim.opt_local.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
        vim.opt_local.foldlevel = 99
        vim.bo.tabstop = 4
        vim.bo.shiftwidth = 4
        vim.bo.softtabstop = 4
        vim.bo.expandtab = true
      end,
    })

    vim.api.nvim_create_autocmd('FileType', {
      pattern = { 'javascript', 'json', 'typescript', 'lua' },
      callback = function()
        vim.opt_local.foldmethod = 'expr'
        vim.opt_local.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
        vim.opt_local.foldlevel = 99
        vim.bo.tabstop = 2
        vim.bo.shiftwidth = 2
        vim.bo.softtabstop = 2
        vim.bo.expandtab = true
      end,
    })

    vim.api.nvim_create_autocmd('FileType', {
      pattern = { 'go', 'gomod', 'gowork', 'gotmpl' },
      callback = function()
        vim.opt_local.foldmethod = 'expr'
        vim.opt_local.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
        vim.opt_local.foldlevel = 99
        vim.bo.tabstop = 4
        vim.bo.shiftwidth = 4
        vim.bo.softtabstop = 4
        vim.bo.expandtab = false
      end,
    })
    require('nvim-treesitter.configs').setup(opts)
  end,
}
