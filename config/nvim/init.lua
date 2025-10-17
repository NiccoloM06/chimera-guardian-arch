-- =============================================================================
--  NEOVIM CONFIGURATION ENTRYPOINT | CHIMERA GUARDIAN ARCH (MODULAR)
--  Loads all modular configuration components.
-- =============================================================================

-- Load core editor settings (appearance, behavior, etc.)
require("user.settings")

-- Load and setup all plugins via lazy.nvim
require("user.plugins")

-- Load custom keybindings
require("user.keymaps")

-- Optional: You could add very specific, top-level settings here if needed,
-- but generally, keeping it clean and sourcing modules is preferred.