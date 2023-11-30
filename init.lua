if vim.g.neovide then
	local neovide = require("core.neovide")
	neovide.init()
end

require("core.options")
require("core.keymaps")

require("config.plugins")
