return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  config = function()
    require("codecompanion").setup({
      display = {
        action_palette = {
          width = 20,
          height = 10,
          prompt = "Prompt ",
          provider = "snacks",
          opts = {
            show_preset_actions = true,
            show_preset_prompts = true,
            enabled = true,
            title = "CodeCompanion actions",
          },
        },

        diff = {
          enabled = true,
          provider = "split"
        },
      },

      prompt_library = {
        markdown = {
          dirs = {
            vim.fn.stdpath("config") .. "/lua/config/utils/prompts",
          },
        },
      },

      adapters = {
        acp = {
          codex = function()
            return require("codecompanion.adapters").extend("codex", {
              defaults = {
                auth_method = "chatgpt",
              },
            })
          end,
        },
      },

      interactions = {
        chat = {
          adapter = "codex",
        },
        inline = {
          adapter = "copilot",
        },
        cmd = {
          adapter = "codex",
        }
      },
    })

    -- 快捷鍵
    vim.keymap.set("n", "<leader>cc", "<cmd>CodeCompanionChat Toggle<cr>", { desc = "Toggle Chat" })
    vim.keymap.set("v", "<leader>cc", "<cmd>CodeCompanionChat Toggle<cr>", { desc = "Toggle Chat" })
    vim.keymap.set("n", "<leader>ca", "<cmd>CodeCompanionActions<cr>", { desc = "Actions" })
    vim.keymap.set("v", "<leader>ca", "<cmd>CodeCompanionActions<cr>", { desc = "Actions" })
  end,
}
