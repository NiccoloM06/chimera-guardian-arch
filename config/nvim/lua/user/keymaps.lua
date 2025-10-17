-- =============================================================================
--  KEYMAPS | CHIMERA GUARDIAN ARCH (Neovim)
--  Centralizes all custom keyboard shortcuts.
-- =============================================================================

local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Set the leader key (used as a prefix for many custom commands)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- --- NORMAL MODE ---

-- Basic File Operations
map("n", "<leader>w", ":w<CR>", { desc = "Write/Save File" })
map("n", "<leader>q", ":q<CR>", { desc = "Quit Window" })
map("n", "<leader>wq", ":wq<CR>", { desc = "Write and Quit" })
map("n", "<leader>Q", ":qa!<CR>", { desc = "Force Quit All" })

-- Navigation & Window Management
map("n", "<C-h>", "<C-w>h", { desc = "Move focus to left window" })
map("n", "<C-l>", "<C-w>l", { desc = "Move focus to right window" })
map("n", "<C-k>", "<C-w>k", { desc = "Move focus to upper window" })
map("n", "<C-j>", "<C-w>j", { desc = "Move focus to lower window" })
map("n", "<leader>v", ":vsplit<CR>", { desc = "Split Vertically" })
map("n", "<leader>s", ":split<CR>", { desc = "Split Horizontally" })

-- Buffer Navigation
map("n", "<S-l>", ":bnext<CR>", { desc = "Next Buffer" })
map("n", "<S-h>", ":bprevious<CR>", { desc = "Previous Buffer" })
map("n", "<leader>bd", ":bdelete<CR>", { desc = "Close Buffer" })

-- File Explorer (nvim-tree)
map("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "Toggle File Explorer" })
map("n", "<leader>fo", ":NvimTreeFindFile<CR>", { desc = "Find Current File in Tree" })

-- Telescope (Fuzzy Finder)
local builtin = require('telescope.builtin')
map('n', '<leader>ff', builtin.find_files, { desc = 'Find Files' })
map('n', '<leader>fg', builtin.live_grep, { desc = 'Live Grep' })
map('n', '<leader>fb', builtin.buffers, { desc = 'Find Buffers' })
map('n', '<leader>fh', builtin.help_tags, { desc = 'Find Help Tags' })

-- --- INSERT MODE ---

-- Quick exit from insert mode
map("i", "jk", "<ESC>", opts)
map("i", "kj", "<ESC>", opts)

-- --- VISUAL MODE ---

-- Move selected lines up/down
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move Line Down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move Line Up" })