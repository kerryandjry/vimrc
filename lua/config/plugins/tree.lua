return {
  "nvim-tree/nvim-tree.lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local nvimtree = require("nvim-tree")

    -- recommended settings from nvim-tree documentation
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1

    -- change color for arrows in tree to light blue
    vim.cmd([[ highlight NvimTreeIndentMarker guifg=#3FC5FF ]])

    -- configure nvim-tree
    nvimtree.setup({
      view = {
        width = 22,
      },
      renderer = {
        icons = {
          glyphs = {
            folder = {
              arrow_closed = "",
              arrow_open = "",
            },
          },
        },
      },
      actions = {
        open_file = {
          quit_on_open = false,
          window_picker = {
            enable = false,
          },
        },
      },
      filters = {
        custom = { ".DS_Store" },
      },
      git = {
        ignore = false,
      },
      on_attach = function(bufnr)
        local api = require("nvim-tree.api")

        local function opts(desc)
          return {
            desc = "nvim-tree: " .. desc,
            buffer = bufnr,
            noremap = true,
            silent = true,
            nowait = true,
          }
        end

        -- ⬇️ 改寫 Enter 為用垂直分割開啟檔案
        vim.keymap.set("n", "<CR>", function()
          api.node.open.vertical()
        end, opts("Open: Vertical Split"))

        -- ⬇️ 可選：Shift+Enter 用橫向 split
        vim.keymap.set("n", "<S-CR>", function()
          api.node.open.horizontal()
        end, opts("Open: Horizontal Split"))
      end,
    })

    -- global keymap
    local keymap = vim.keymap
    keymap.set("n", "<F9>", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle file explorer" })
  end,
}
