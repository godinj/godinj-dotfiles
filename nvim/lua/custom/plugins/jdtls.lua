return {
  'mfussenegger/nvim-jdtls',
  ft = 'java',
  config = function()
    -- Basic configuration for nvim-jdtls
    require('jdtls').start_or_attach {
      cmd = { 'jdtls' },
      root_dir = require('jdtls.setup').find_root { '.git', 'mvn', 'gradle' },
      init_options = {
        bundles = {},
      },
      -- Add additional configuration as needed
    }
  end,
}
