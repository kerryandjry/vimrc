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
	require("config.plugins.gruvbox"),
	require("config.plugins.comment"),
	require("config.plugins.toggleterm"),
	require("config.plugins.telescope"),
	require("config.plugins.snippets"),
	require("config.plugins.treesitter"),
	require("config.plugins.autopairs"),
	require("config.plugins.lualine"),
	require("config.plugins.copilot"),
	require("config.plugins.tree"),
	require("config.plugins.surround"),
	require("config.plugins.autocomplete"),
	require("config.plugins.illuminate"),
	require("config.plugins.which-key"),
	require("config.plugins.nvim-gpt"),
	require("config.plugins.bookmarks"),
	require("config.plugins.yazi"),
	-- require("config.plugins.flash"),
	require("config.plugins.trouble"),
	require("config.plugins.barbar"),
	-- require("config.plugins.discord-presence"),

	-- lsp setup
	require("config.plugins.lsp.lspconfig"),
	require("config.plugins.lsp.null-ls"),
	require("config.plugins.lsp.mason"),
	require("config.plugins.lsp.lspsaga"),

	-- TODO: add dap

	checker = {
		enable = true,
		notify = false,
	},
	change_detection = {
		notify = false,
	},
})
