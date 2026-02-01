return {
  "hrsh7th/nvim-cmp",
  event = "InsertEnter",
  dependencies = {
    "hrsh7th/cmp-buffer",   -- source for text in buffer
    "hrsh7th/cmp-path",     -- source for file system paths
    "hrsh7th/cmp-nvim-lsp", -- source for LSP
  },
  config = function()
    local cmp = require("cmp")

    vim.opt.completeopt = "menu,menuone,noselect"
    cmp.setup({
      mapping = cmp.mapping.preset.insert({
        ["<CR>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.confirm({ select = false })
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<Tab>"] = cmp.mapping.select_next_item(),
        ["<S-Tab>"] = cmp.mapping.select_prev_item(),
      }),
      -- sources for autocompletion
      sources = cmp.config.sources({
        { name = "nvim_lsp" }, -- lsp
        { name = "buffer" },   -- text within current buffer
        { name = "path" },     -- file system paths
      }),
    })
  end,
}
