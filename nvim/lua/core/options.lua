-- views can only be fully collapsed with the global statusline
vim.opt.laststatus = 3

vim.o.relativenumber = true
vim.opt.foldmethod = 'indent'
vim.opt.foldlevelstart = 99
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'neo-tree',
  callback = function()
    vim.api.nvim_set_hl(0, 'NeoTreeGitUntracked', { fg = '#FE8019' })
  end,
})
