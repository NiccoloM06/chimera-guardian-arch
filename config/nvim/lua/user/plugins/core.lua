-- =============================================================================
--  CORE PLUGINS | CHIMERA GUARDIAN ARCH (Neovim)
--  Essential plugins for UI, themes, and base editor functionality.
-- =============================================================================

return {
  -- Colorscheme: Provides the main visual theme.
  {
    "folke/tokyonight.nvim",
    lazy = false, -- Load this theme immediately at startup
    priority = 1000, -- Ensure it loads before other plugins
    opts = { style = "night" }, -- Use the 'night' variant
  },

  -- File Explorer: A tree-style file explorer panel.
  {
    "nvim-tree/nvim-tree.lua",
    version = "*", -- Pin to major version for stability
    lazy = false, -- Load it early
    dependencies = {
      "nvim-tree/nvim-web-devicons", -- Required for file icons
    },
    config = function()
      -- Basic setup, uses default settings which are excellent.
      require("nvim-tree").setup({})
    end,
  },

  -- Status Line: A powerful and informative status line at the bottom.
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require('lualine').setup({
        options = {
          theme = 'tokyonight', -- Match the colorscheme
          icons_enabled = true,
          component_separators = { left = '', right = ''}, -- Rounded separators
          section_separators = { left = '', right = ''},   -- Powerline-style separators
        }
      })
    end
  },

  -- Icon Support: Provides the icons used by nvim-tree and lualine.
  { "nvim-tree/nvim-web-devicons" },

}