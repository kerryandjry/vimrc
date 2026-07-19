require("core.options")
require("core.keymaps")
require("core.utils")
require("core.tasks")
require("config.plugins")
require("core.lsp")

-- Used by install.sh and nvim-doctor to verify that this configuration loaded
-- completely, rather than merely finding a working Neovim executable.
vim.g.portable_nvim_loaded = 1
