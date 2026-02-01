-- leader key to spaceto
vim.g.mapleader = ","
local keymap = vim.keymap -- for conciseness
local opt = { noremap = true, silent = true }

keymap.set("n", "Z", "ZZ")
keymap.set("n", "Q", "ZQ")

keymap.set("n", "<F1>", ":w<cr>")

-- F2: toggle terminal in current directory
local term_win = nil
local term_buf = nil
local function close_term()
  if term_win and vim.api.nvim_win_is_valid(term_win) then
    vim.api.nvim_win_close(term_win, true)
  end
  if term_buf and vim.api.nvim_buf_is_valid(term_buf) then
    vim.api.nvim_buf_delete(term_buf, { force = true })
  end
  term_win = nil
  term_buf = nil
end

local function open_term()
  local cwd = vim.fn.getcwd()
  vim.cmd("botright split")
  term_win = vim.api.nvim_get_current_win()
  vim.cmd("terminal")
  term_buf = vim.api.nvim_get_current_buf()
  vim.bo[term_buf].buflisted = false
  vim.bo[term_buf].bufhidden = "wipe"
  vim.cmd("startinsert")
  vim.cmd("lcd " .. vim.fn.fnameescape(cwd))
end

local function toggle_term()
  if term_win and vim.api.nvim_win_is_valid(term_win) then
    close_term()
    return
  end
  if term_buf and vim.api.nvim_buf_is_valid(term_buf) then
    close_term()
  end
  open_term()
end

keymap.set("n", "<F2>", toggle_term, { noremap = true, silent = true, desc = "toggle terminal (cwd)" })
keymap.set("t", "<F2>", function()
  vim.cmd("stopinsert")
  toggle_term()
end, { noremap = true, silent = true, desc = "toggle terminal (cwd)" })

keymap.set("n", "<F9>", "<cmd>Yazi<cr>", { desc = "Yazi" })

-- IlluminatedWord
vim.api.nvim_create_autocmd({ "BufEnter" }, { command = ":hi link IlluminatedWordText Visual" })
vim.api.nvim_create_autocmd({ "BufEnter" }, { command = ":hi link IlluminatedWordRead Visual" })
vim.api.nvim_create_autocmd({ "BufEnter" }, { command = ":hi link IlluminatedWordWrite Visual" })

-- automactic formatic when save
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    vim.lsp.buf.format({ async = false })
  end,
})

vim.keymap.set('n', '<F3>', function()
  local ft = vim.bo.filetype
  local filename = vim.fn.expand('%:p')
  local build_dir = "build"
  local exe = build_dir .. "/main"

  if ft == "cpp" then
    -- 自動 build 並執行
    vim.cmd("w")                 -- 先儲存
    vim.fn.mkdir(build_dir, "p") -- 確保有 build 資料夾
    vim.cmd("!cmake -S . -B " .. build_dir .. " && cmake --build " .. build_dir .. " && " .. exe)
  elseif ft == "python" then
    vim.cmd("w")
    vim.cmd("!python3 " .. filename)
  else
    print("F3: 不支援的檔案類型")
  end
end, { noremap = true, silent = true })
-- del default keymap
vim.keymap.del('n', 'gri')
vim.keymap.del('n', 'grr')
vim.keymap.del('n', 'gra')
vim.keymap.del('n', 'grn')

-- barbar --
keymap.set("n", "<leader>1", "<cmd>BufferGoto 1<cr>", opt)
keymap.set("n", "<leader>2", "<cmd>BufferGoto 2<cr>", opt)
keymap.set("n", "<leader>3", "<cmd>BufferGoto 3<cr>", opt)
keymap.set("n", "<leader>4", "<cmd>BufferGoto 4<cr>", opt)
keymap.set("n", "<leader>5", "<cmd>BufferGoto 5<cr>", opt)
keymap.set("n", "<leader>6", "<cmd>BufferGoto 6<cr>", opt)
keymap.set("n", "<leader>7", "<cmd>BufferGoto 7<cr>", opt)
keymap.set("n", "<leader>d", function()
  -- 計算有多少個已載入的普通 buffer
  local buffers = vim.tbl_filter(function(buf)
    return vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted
  end, vim.api.nvim_list_bufs())

  if #buffers <= 1 then
    vim.cmd("quit!")
  else
    vim.cmd("BufferClose!")
  end
end, { noremap = true, silent = true, desc = "close buf" })

-- nvim-gpt
-- keymap.set("n", "<c-c>", ":ChatGPT<cr>")
-- keymap.set("n", "<leader>c", "<cmd>ChatGPTCompleteCode<cr>")
--
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
