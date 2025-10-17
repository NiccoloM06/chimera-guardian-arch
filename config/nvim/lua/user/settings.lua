-- =============================================================================
--  CORE EDITOR SETTINGS | CHIMERA GUARDIAN ARCH (Neovim)
--  Defines the fundamental behavior and appearance of the editor.
-- =============================================================================

local opt = vim.opt -- For conciseness

-- --- APPEARANCE ---
opt.termguicolors = true -- Enable 24-bit RGB colors
opt.number = true        -- Show line numbers
opt.relativenumber = true  -- Show relative line numbers for easier jumping
opt.signcolumn = "yes"   -- Always show the sign column (for LSP diagnostics, Git signs)
opt.cursorline = true    -- Highlight the current line
opt.scrolloff = 8        -- Keep 8 lines visible above/below cursor when scrolling

-- --- BEHAVIOR ---
opt.mouse = "a"           -- Enable mouse support in all modes
opt.clipboard = "unnamedplus" -- Use system clipboard for copy/paste
opt.swapfile = false      -- Disable swap files
opt.backup = false        -- Disable backup files
opt.undofile = true       -- Enable persistent undo history
opt.undodir = vim.fn.stdpath('data') .. '/undodir' -- Set undo directory
if vim.fn.isdirectory(opt.undodir:get()) == 0 then
    vim.fn.mkdir(opt.undodir:get(), 'p')
end

-- --- SEARCHING ---
opt.ignorecase = true     -- Case-insensitive searching...
opt.smartcase = true      -- ...unless the pattern contains an uppercase letter
opt.hlsearch = true       -- Highlight search results
opt.incsearch = true      -- Show matches incrementally as you type

-- --- INDENTATION & TABS ---
opt.tabstop = 4           -- Number of visual spaces per tab
opt.softtabstop = 4       -- Number of spaces inserted when pressing Tab
opt.shiftwidth = 4        -- Number of spaces for auto-indentation
opt.expandtab = true      -- Use spaces instead of tabs
opt.smartindent = true    -- Enable smart auto-indentation

-- --- EDITOR PERFORMANCE & UX ---
opt.updatetime = 250      -- Faster update time for plugins (e.g., cursor hold events)
opt.timeoutlen = 300      -- Shorter delay for key sequence timeouts
opt.splitright = true     -- Vertical splits open to the right
opt.splitbelow = true     -- Horizontal splits open below
opt.list = true           -- Show whitespace characters
opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' } -- Customize whitespace chars
opt.wrap = false          -- Disable line wrapping by default
opt.showmode = false      -- Don't show the mode in the command line (handled by lualine)
opt.breakindent = true    -- Maintain indentation on wrapped lines if wrap is enabled