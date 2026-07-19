local parsers = {
  "bash",
  "c",
  "cmake",
  "cpp",
  "dart",
  "go",
  "html",
  "java",
  "javascript",
  "lua",
  "markdown",
  "markdown_inline",
  "prisma",
  "python",
  "query",
  "regex",
  "typescript",
  "vim",
  "vimdoc",
  "yaml",
}

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local treesitter = require("nvim-treesitter")
      local legacy_root = vim.fn.stdpath("data") .. "/lazy/nvim-treesitter"
      for _, directory in ipairs({ "parser", "parser-info" }) do
        local legacy_path = legacy_root .. "/" .. directory
        if vim.uv.fs_stat(legacy_path) then
          vim.fn.delete(legacy_path, "rf")
        end
      end
      -- Explicitly prepend the managed parser directory so stale parser
      -- binaries left inside a plugin checkout can never shadow it.
      treesitter.setup({
        install_dir = vim.fn.stdpath("data") .. "/site",
      })

      local function parser_failure(message)
        if #vim.api.nvim_list_uis() == 0 then
          vim.api.nvim_err_writeln(message)
          vim.cmd("cquit")
        else
          error(message)
        end
      end

      vim.api.nvim_create_user_command("PortableTSInstall", function()
        local installed = treesitter.install(parsers, {
          force = true,
          max_jobs = 4,
          summary = true,
        }):wait(300000)
        if not installed then
          parser_failure("one or more Treesitter parsers failed to install")
        end
      end, { desc = "Install parsers required by this configuration" })

      vim.api.nvim_create_user_command("PortableTSUpdate", function()
        local updated = treesitter.update(parsers, { max_jobs = 4, summary = true }):wait(300000)
        local installed = treesitter.install(parsers, { max_jobs = 4, summary = true }):wait(300000)
        if not updated or not installed then
          parser_failure("one or more Treesitter parsers failed to update")
        end
      end, { desc = "Update parsers required by this configuration" })

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("portable-treesitter", { clear = true }),
        pattern = parsers,
        callback = function()
          pcall(vim.treesitter.start)
          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
    opts = {
      enable = true,
      max_lines = 0,
      multiline_threshold = 20,
      mode = "cursor",
    },
    keys = {
      {
        "[c",
        function()
          require("treesitter-context").go_to_context()
        end,
        desc = "Go to Treesitter context",
      },
    },
  },
}
