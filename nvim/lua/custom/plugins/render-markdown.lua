return {
  'MeanderingProgrammer/render-markdown.nvim',
  opts = {
    anti_conceal = { enabled = false },
  },
  keys = {
    { '<leader>tm', '<cmd>RenderMarkdown toggle<cr>', desc = '[T]oggle [M]arkdown render' },
  },
}
