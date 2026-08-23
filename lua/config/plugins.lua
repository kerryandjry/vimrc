local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json"
local lock = vim.json.decode(table.concat(vim.fn.readfile(lockfile), "\n"))
local lazy_commit = lock["lazy.nvim"] and lock["lazy.nvim"].commit

if not lazy_commit then
  error("lazy.nvim is missing from " .. lockfile)
end
if not vim.uv.fs_stat(lazypath) then
  if vim.env.PORTABLE_NVIM_VERIFY == "1" then
    error("lazy.nvim is not installed at the locked revision: " .. lazypath)
  end
  local clone = vim.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--no-checkout",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  }):wait()
  if clone.code ~= 0 then
    vim.fn.delete(lazypath, "rf")
    error("failed to clone lazy.nvim: " .. (clone.stderr or "unknown error"))
  end
  local checkout = vim.system({ "git", "-C", lazypath, "checkout", "--detach", lazy_commit }):wait()
  if checkout.code ~= 0 then
    vim.fn.delete(lazypath, "rf")
    error("failed to checkout locked lazy.nvim revision: " .. (checkout.stderr or "unknown error"))
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  require("config.plugins.tokyonight"),
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
  require("config.plugins.markdown"),
}, {
  install = {
    missing = vim.env.PORTABLE_NVIM_VERIFY ~= "1",
  },
  checker = {
    enable = true,
    notify = false,
  },
  change_detection = {
    notify = false,
  },
  rocks = {
    enabled = false,
  },
})
