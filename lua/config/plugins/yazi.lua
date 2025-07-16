return {
  "mikavilpas/yazi.nvim",
  event = "VeryLazy",
  dependencies = {
    { "nvim-lua/plenary.nvim", lazy = true },
  },
  keys = {
    -- 👇 in this section, choose your own keymappings!
    {
      "<leader>y",
      mode = { "n", "v" },
      "<cmd>Yazi<cr>",
      desc = "Yazi",
    },
  },
  ---@type YaziConfig | {}
  opts = {
    -- if you want to open yazi instead of netrw, see below for more info
    open_for_directories = false,
    keymaps = {
      open_file_in_vertical_split = "<C-v>",
    },
  },
  init = function()
    vim.g.loaded_netrwPlugin = 1
  end,
}
