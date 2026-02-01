return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  init = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 300
  end,
  opts = {
    icons = {
      breadcrumb = "»",
      separator = "➜",
      group = "+",
    },
  },
  config = function()
    local wk = require("which-key")
    wk.add({
      { "<leader>1", hidden = true },
      { "<leader>2", hidden = true },
      { "<leader>3", hidden = true },
      { "<leader>4", hidden = true },
      { "<leader>5", hidden = true },
      { "<leader>6", hidden = true },
      { "<leader>7", hidden = true },
      { "ge",        hidden = true },
      { "gf",        hidden = true },
      { "gg",        hidden = true },
      { "gi",        hidden = true },
      { "gn",        hidden = true },
      { "gN",        hidden = true },
      { "gO",        hidden = true },
      { "gt",        hidden = true },
      { "gT",        hidden = true },
      { "gu",        hidden = true },
      { "gU",        hidden = true },
      { "gv",        hidden = true },
      { "gw",        hidden = true },
      { "gx",        hidden = true },
      { "g%",        hidden = true },
      { "g,",        hidden = true },
      { "g;",        hidden = true },
      { "g~",        hidden = true },
      { "g'",        hidden = true },
      { "g`",        hidden = true },
    })
  end,
}
