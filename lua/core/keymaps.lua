-- leader key to space
vim.g.mapleader = ","
local keymap = vim.keymap -- for conciseness
local map = vim.api.nvim_set_keymap
local opt = { noremap = true, silent = true }

keymap.set("n", "Z", "ZZ")
keymap.set("n", "Q", "ZQ")

keymap.set({ "n", "i", "v" }, "<F1>", ":w<cr>")

keymap.set("n", "<F9>", ":NvimTreeToggle<cr>")

-- telescope
keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>") -- find files within current working directory, respects .gitignore
keymap.set("n", "<leader>fs", "<cmd>Telescope live_grep<cr>") -- find string in current working directory as you type
keymap.set("n", "<leader>fc", "<cmd>Telescope grep_string<cr>") -- find string under cursor in current working directory
keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<cr>") -- list open buffers in current neovim instance
keymap.set("n", "<leader>fh", "<cmd>Telescope help_tags<cr>") -- list available help tags
keymap.set("n", "<leader>fc", "<cmd>Telescope grep_string<cr>", { desc = "Find string under cursor in cwd" }) -- find string under cursor in current working directory

keymap.set("n", "<leader>o", "<cmd>Telescope oldfiles<cr>") -- list recently opened files
-- keymap.set("n", "<leader>k", "<cmd>Telescope live_grep initial_mode=insert<cr>") -- list strings in current working directory as you type

keymap.set("n", "ml", "<cmd>Telescope bookmarks list<cr>") -- bookmarks list

-- lazygit
keymap.set("n", "<c-g>", ":lazygit<cr>")

-- terminal
map("n", "<leader>t", "<cmd>ToggleTerm<cr>", opt)
-- dap
-- keymap.set(
-- 	"n",
-- 	"<leader>df",
-- 	"<cmd>lua require'dap'.toggle_breakpoint(); require 'config.plugins.dap.dap-util'.store_breakpoints(true)<cr>",
-- 	opt
-- )
-- keymap.set("n", "<leader>db", "<cmd>lua require'dap'.set_breakpoint<cr>", opt)
-- keymap("n", "<leader>dr", "lua require'dap'.repl.open()<cr>", opts)
-- keymap.set("n", "<F9>", "<cmd>lua require'dap'.run_last()<cr>", opt)
-- keymap.set("n", "<F10>", '<cmd>lua require"config.plugins.dap.dap-util".reload_continue()<CR>', opt)
-- keymap.set("n", "<F4>", "<cmd>lua require'dap'.terminate()<cr>", opt)
-- keymap.set("n", "<F5>", "<cmd>lua require'dap'.continue()<cr>", opt)
-- keymap.set("n", "<F6>", "<cmd>lua require'dap'.step_over()<cr>", opt)
-- keymap.set("n", "<F7>", "<cmd>lua require'dap'.step_into()<cr>", opt)
-- keymap.set("n", "<F8>", "<cmd>lua require'dap'.step_out()<cr>", opt)
-- keymap.set("n", "K", "<cmd>lua require'dapui'.eval()<cr>", opt)

vim.api.nvim_create_autocmd({ "BufEnter" }, { command = ":hi link IlluminatedWordText Visual" })
vim.api.nvim_create_autocmd({ "BufEnter" }, { command = ":hi link IlluminatedWordRead Visual" })
vim.api.nvim_create_autocmd({ "BufEnter" }, { command = ":hi link IlluminatedWordWrite Visual" })

-- nvim-gpt
keymap.set("n", "<leader>g", ":ChatGPT<cr>")
keymap.set("n", "<leader>c", ":ChatGPTCompleteCode<cr>")
