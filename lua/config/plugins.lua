local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- require("config.plugins.gruvbox"),
  require("config.plugins.tokyonight"),
  require("config.plugins.comment"),
  require("config.plugins.treesitter"),
  require("config.plugins.autopairs"),
  require("config.plugins.lualine"),
  -- require("config.plugins.surround"),
  require("config.plugins.autocomplete"),
  require("config.plugins.illuminate"),
  require("config.plugins.which-key"),
  require("config.plugins.yazi"),
  require("config.plugins.lazygit"),
  require("config.plugins.snacks"),
  require("config.plugins.barbar"),
  require("config.plugins.codecompanion"),

  checker = {
    enable = true,
    notify = false,
  },
  change_detection = {
    notify = false,
  },
})
