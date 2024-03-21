-- leader key to space
vim.g.mapleader = ","
local keymap = vim.keymap -- for conciseness
local opt = { noremap = true, silent = true }

keymap.set("n", "Z", "ZZ")
keymap.set("n", "Q", "ZQ")

keymap.set("n", "<F1>", ":w<cr>")

keymap.set("n", "<F9>", ":NvimTreeToggle<cr>")

-- IlluminatedWord
vim.api.nvim_create_autocmd({ "BufEnter" }, { command = ":hi link IlluminatedWordText Visual" })
vim.api.nvim_create_autocmd({ "BufEnter" }, { command = ":hi link IlluminatedWordRead Visual" })
vim.api.nvim_create_autocmd({ "BufEnter" }, { command = ":hi link IlluminatedWordWrite Visual" })

-- telescope
keymap.set("n", "<leader>f", "<cmd>Telescope find_files<cr>") -- find files within current working directory, respects .gitignore
keymap.set("n", "<leader>s", "<cmd>Telescope live_grep<cr>") -- find string in current working directory as you type
keymap.set("n", "<leader>o", "<cmd>Telescope oldfiles<cr>") -- list recently opened files
keymap.set("n", "ml", "<cmd>Telescope bookmarks list<cr>") -- bookmarks list
-- keymap.set("n", "<leader>fc", "<cmd>Telescope grep_string<cr>") -- find string under cursor in current working directory
-- keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<cr>") -- list open buffers in current neovim instance
-- keymap.set("n", "<leader>fh", "<cmd>Telescope help_tags<cr>") -- list available help tags

-- lazygit
keymap.set("n", "<c-g>", ":lazygit<cr>")

-- nvim-gpt
keymap.set("n", "<c-c>", ":ChatGPT<cr>")
keymap.set("n", "<leader>c", "<cmd>ChatGPTCompleteCode<cr>")

keymap.set("n", "<leader>xx", ":TroubleToggle<cr>")
keymap.set("n", "<leader>xq", "TroubleToggle quickfix")
-- keymap.set("n", "<leader>xw", function()
-- 	require("trouble").toggle("workspace_diagnostics")
-- end)
-- keymap.set("n", "<leader>xd", function()
-- 	require("trouble").toggle("document_diagnostics")
-- end)
-- keymap.set("n", "gR", function()
-- 	require("trouble").toggle("lsp_references")
-- end)

-- barbar
keymap.set("n", "<leader>1", "<cmd>BufferGoto 1<cr>", opt)
keymap.set("n", "<leader>2", "<cmd>BufferGoto 2<cr>", opt)
keymap.set("n", "<leader>3", "<cmd>BufferGoto 3<cr>", opt)
keymap.set("n", "<leader>4", "<cmd>BufferGoto 4<cr>", opt)
keymap.set("n", "<leader>5", "<cmd>BufferGoto 5<cr>", opt)
keymap.set("n", "<leader>6", "<cmd>BufferGoto 6<cr>", opt)
keymap.set("n", "<leader>7", "<cmd>BufferGoto 7<cr>", opt)

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
