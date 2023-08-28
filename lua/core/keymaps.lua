-- leader key to space
vim.g.mapleader = ","

local keymap = vim.keymap -- for conciseness
local map = vim.api.nvim_set_keymap
local opt = { noremap = true, silent = true }

keymap.set("n", "Z", "ZZ")
keymap.set("n", "Q", "ZQ")

keymap.set("n", "<F9>", ":NvimTreeToggle<cr>")

keymap.set({ "n", "i", "v" }, "<F10>", ":Neoformat<cr>")
keymap.set("n", "gpt", ":Neural<cr>")

-- telescope
keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>") -- find files within current working directory, respects .gitignore
keymap.set("n", "<leader>fs", "<cmd>Telescope live_grep<cr>") -- find string in current working directory as you type
keymap.set("n", "<leader>fc", "<cmd>Telescope grep_string<cr>") -- find string under cursor in current working directory
keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<cr>") -- list open buffers in current neovim instance
keymap.set("n", "<leader>fh", "<cmd>Telescope help_tags<cr>") -- list available help tags

keymap.set("n", "<c-g>", ":!lazygit<cr>")
