return {
  "akinsho/toggleterm.nvim",
  version = "*",
  config = function()
    require("toggleterm").setup({
      size = 10,
      open_mapping = [[<F2>]],
    })
    local Terminal = require("toggleterm.terminal").Terminal
    local lazygit = Terminal:new({
      cmd = "lazygit",
      direction = "float",
    })

    -- lazygit
    function lazygit_toggle()
      lazygit:toggle()
    end

    vim.api.nvim_set_keymap("n", "<leader>g", "<Cmd>lua lazygit_toggle()<CR>",
      { noremap = true, silent = true, desc = "Lazygit" })
  end,
}
