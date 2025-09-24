-- nvim v0.8.0
return {
  "kdheepak/lazygit.nvim",
  lazy = true,
  cmd = {
    "LazyGit",
    "LazyGitConfig",
    "LazyGitCurrentFile",
    "LazyGitFilter",
    "LazyGitFilterCurrentFile",
  },
  -- optional for floating window border decoration
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  keys = {
    -- 👇 in this section, choose your own keymappings!
    {
      "<leader>g",
      mode = { "n", "v" },
      "<cmd>LazyGit<cr>",
      desc = "LazyGit",
    },
  },
}
