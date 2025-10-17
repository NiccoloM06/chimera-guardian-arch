-- =============================================================================
--  DEVELOPMENT PLUGINS | CHIMERA GUARDIAN ARCH (Neovim)
--  Plugins enhancing the coding experience (LSP, completion, Git, etc.).
-- =============================================================================

return {

  -- LSP Configuration: Manages Language Server Protocol setup.
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      -- Automatically installs LSP servers
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",

      -- Autocompletion engine
      "hrsh7th/nvim-cmp",
      "hrsh7th/cmp-nvim-lsp", -- Source for LSP suggestions
      "hrsh7th/cmp-buffer",  -- Source for buffer words
      "hrsh7th/cmp-path",    -- Source for filesystem paths

      -- Snippets engine
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip", -- Snippets source for nvim-cmp
    },
    config = function()
      -- Setup Mason (LSP server installer)
      require("mason").setup()
      require("mason-lspconfig").setup()

      -- Setup nvim-cmp (autocompletion)
      local cmp = require('cmp')
      local luasnip = require('luasnip')

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.abort(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept completion with Enter
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
          { name = 'buffer' },
          { name = 'path' },
        })
      })

      -- Setup LSP servers (using mason-lspconfig)
      local capabilities = require('cmp_nvim_lsp').default_capabilities()
      require("mason-lspconfig").setup_handlers {
        -- Default handler: setup servers with default options and cmp capabilities
        function (server_name)
          require('lspconfig')[server_name].setup {
            capabilities = capabilities
          }
        end,
        -- Example custom setup for lua_ls (Lua language server)
        ["lua_ls"] = function ()
          require('lspconfig').lua_ls.setup {
             capabilities = capabilities,
             settings = { Lua = { diagnostics = { globals = {'vim'} } } }
          }
        end,
      }
    end
  },

  -- Git Integration: Adds Git signs in the gutter and integrates with Lazygit.
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require('gitsigns').setup()
    end
  },

  -- Syntax Highlighting: Improved and faster syntax highlighting.
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate", -- Command to install/update parsers
    config = function()
      require('nvim-treesitter.configs').setup({
        ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "bash", "python", "yaml", "json" }, -- Install parsers for common languages
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },

  -- Telescope: Fuzzy finder for files, buffers, code symbols, etc.
  {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.x', -- Recommended tag
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
        require('telescope').setup({})
        -- Keymaps for Telescope
        local builtin = require('telescope.builtin')
        vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Find Files' })
        vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Live Grep' })
        vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Find Buffers' })
        vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Find Help Tags' })
    end
  },
}