return {
  'mfussenegger/nvim-jdtls',
  ft = 'java',
  config = function()
    local jdtls = require 'jdtls'
    local root_dir = require('jdtls.setup').find_root({ 'packageInfo' }, 'Config')

    -- Bemol workspace folders
    local ws_folders_jdtls = {}
    if root_dir then
      local file = io.open(root_dir .. '/.bemol/ws_root_folders')
      if file then
        for line in file:lines() do
          table.insert(ws_folders_jdtls, 'file://' .. line)
        end
        file:close()
      end
    end

    -- Lombok support via Mason
    local lombok_jar = vim.fn.expand '$MASON/share/jdtls/lombok.jar'
    local cmd = { 'jdtls', '--java-executable', '/Library/Java/JavaVirtualMachines/amazon-corretto-21.jdk/Contents/Home/bin/java' }
    if vim.uv.fs_stat(lombok_jar) then
      table.insert(cmd, '--jvm-arg=-javaagent:' .. lombok_jar)
    end

    jdtls.start_or_attach {
      cmd = cmd,
      root_dir = root_dir,
      init_options = {
        workspaceFolders = ws_folders_jdtls,
        bundles = {},
      },
      settings = {
        java = {
          import = {
            gradle = { enabled = false },
          },
        },
      },
    }
  end,
}
