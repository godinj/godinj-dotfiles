return {
  'yetone/avante.nvim',
  -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
  -- ⚠️ must add this setting! ! !
  build = vim.fn.has 'win32' ~= 0 and 'powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false' or 'make',
  event = 'VeryLazy',
  version = false, -- Never set this value to "*"! Never!
  ---@module 'avante'
  ---@type avante.Config
  opts = {
    -- add any opts here
    -- this file can contain specific instructions for your project
    instructions_file = 'avante.md',
    -- for example
    provider = 'ollama',
    providers = {
      -- claude = {
      --   endpoint = 'https://api.anthropic.com',
      --   model = 'claude-sonnet-4-20250514',
      --   timeout = 30000, -- Timeout in milliseconds
      --   extra_request_body = {
      --     temperature = 0.75,
      --     max_tokens = 20480,
      --   },
      -- },
      openai = {
        endpoint = 'https://api.openai.com/v1', -- The LLM API endpoint
        model = 'gpt-4o-mini', -- The LLM model name
        timeout = 30000, -- Timeout in milliseconds
        extra_request_body = {
          temperature = 0.75,
          max_tokens = 4096,
        },
      },
      -- moonshot = {
      --   endpoint = 'https://api.moonshot.ai/v1',
      --   model = 'kimi-k2-0711-preview',
      --   timeout = 30000, -- Timeout in milliseconds
      --   extra_request_body = {
      --     temperature = 0.75,
      --     max_tokens = 32768,
      --   },
      -- },
      ollama = {
        endpoint = 'http://localhost:11434', -- Default local endpoint
        -- model = 'qwen2.5-coder:7b-instruct', -- Specify the model you have pulled
        model = 'qwen3:30b-a3b', -- Specify the model you have pulled
        -- Optional: Advanced options for Ollama API
        extra_request_body = {
          -- num_predict = 4096, -- Controls max_tokens
          temperature = 0.75,
          max_tokens = 32768,
          -- max_tokens = 4096,
          -- disable_tools = true,
        },
      },
    },
  },
  dependencies = {
    'nvim-lua/plenary.nvim',
    'MunifTanjim/nui.nvim',
    --- The below dependencies are optional,
    'nvim-mini/mini.pick', -- for file_selector provider mini.pick
    'nvim-telescope/telescope.nvim', -- for file_selector provider telescope
    'hrsh7th/nvim-cmp', -- autocompletion for avante commands and mentions
    'ibhagwan/fzf-lua', -- for file_selector provider fzf
    'stevearc/dressing.nvim', -- for input provider dressing
    'folke/snacks.nvim', -- for input provider snacks
    'nvim-tree/nvim-web-devicons', -- or echasnovski/mini.icons
    'zbirenbaum/copilot.lua', -- for providers='copilot'
    {
      -- support for image pasting
      'HakonHarnes/img-clip.nvim',
      event = 'VeryLazy',
      opts = {
        -- recommended settings
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name = false,
          drag_and_drop = {
            insert_mode = true,
          },
          -- required for Windows users
          use_absolute_path = true,
        },
      },
    },
    {
      -- Make sure to set this up properly if you have lazy=true
      'MeanderingProgrammer/render-markdown.nvim',
      opts = {
        file_types = { 'markdown', 'Avante' },
      },
      ft = { 'markdown', 'Avante' },
    },
  },
  -- config = function()
  -- require('avante').setup {
  -- system_prompt as function ensures LLM always has latest MCP server state
  -- This is evaluated for every message, even in existing chats
  system_prompt = function()
    local hub = require('mcphub').get_hub_instance()
    return hub and hub:get_active_servers_prompt() or ''
  end,
  -- Using function prevents requiring mcphub before it's loaded
  custom_tools = function()
    return {
      require('mcphub.extensions.avante').mcp_tool(),
    }
  end,
  -- },
  -- end,
}
-- return {}
