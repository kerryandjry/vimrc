require("core.options")
require("core.keymaps")
require("core.utils")
require("core.tasks")
require("config.plugins")
require("core.lsp")

local hammerspoon_cli = vim.env.TERMINAL_AUTO_ENGLISH == "1"
	and vim.fn.has("mac") == 1
	and vim.fn.exepath("hs")
	or ""
if hammerspoon_cli ~= "" then
	local input_source_group = vim.api.nvim_create_augroup("EnglishNormalMode", { clear = true })
	vim.api.nvim_create_autocmd({ "VimEnter", "InsertLeave", "CmdlineLeave" }, {
		group = input_source_group,
		callback = function()
			vim.fn.jobstart({ hammerspoon_cli, "-c", "setEnglishInputSource()" }, { detach = true })
		end,
		desc = "Use the US input source in Normal mode",
	})
end

-- Used by install.sh and nvim-doctor to verify that this configuration loaded
-- completely, rather than merely finding a working Neovim executable.
vim.g.portable_nvim_loaded = 1
