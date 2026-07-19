-- leader key to spaceto
vim.g.mapleader = ","
local keymap = vim.keymap -- for conciseness
local opt = { noremap = true, silent = true }

keymap.set("n", "Z", "<cmd>wq<cr>", { desc = "save and quit" })
keymap.set("x", "Z", "<esc><cmd>wq<cr>", { desc = "save and quit" })
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

keymap.set("n", "<F9>", "<cmd>Yazi toggle<cr>", { desc = "toggle Yazi" })

-- IlluminatedWord
vim.api.nvim_create_autocmd({ "BufEnter" }, { command = ":hi link IlluminatedWordText Visual" })
vim.api.nvim_create_autocmd({ "BufEnter" }, { command = ":hi link IlluminatedWordRead Visual" })
vim.api.nvim_create_autocmd({ "BufEnter" }, { command = ":hi link IlluminatedWordWrite Visual" })

-- del default keymap
pcall(vim.keymap.del, 'n', 'gri')
pcall(vim.keymap.del, 'n', 'grr')
pcall(vim.keymap.del, 'n', 'gra')
pcall(vim.keymap.del, 'n', 'grn')

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

-- automactic switch to US afer entering normal mode in vim --
local ime_switch_available = vim.fn.has("mac") == 1 and vim.fn.executable("hs") == 1
local function set_ime_us()
  vim.fn.jobstart({
    "hs", "-c", 'hs.keycodes.currentSourceID("com.apple.keylayout.US")'
  }, { detach = true })
end

local ime_timer = nil
if ime_switch_available then
  vim.api.nvim_create_autocmd("InsertLeave", {
    callback = function()
      -- debounce: 50ms 內多次觸發只做一次
      if ime_timer then
        ime_timer:stop(); ime_timer:close()
      end
      ime_timer = vim.loop.new_timer()
      ime_timer:start(50, 0, vim.schedule_wrap(function()
        set_ime_us()
      end))
    end,
  })
end
