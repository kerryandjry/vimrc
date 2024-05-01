return {
	"williamboman/mason.nvim",
	dependencies = {
		"williamboman/mason-lspconfig.nvim",
    "WhoIsSethDaniel/mason-tool-installer.nvim",
	},
	config = function()
		-- import mason plugin safely
		local mason = require("mason")

		-- import mason-lspconfig plugin safely
		local mason_lspconfig = require("mason-lspconfig")

		-- import mason-null-ls plugin safely
		local mason_tool_installer = require("mason-tool-installer")

		-- enable mason
		mason.setup({
			ui = {
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		})

		mason_lspconfig.setup({
			-- list of servers for mason to install
			ensure_installed = {
				"clangd",
				"lua_ls",
        "pyright",
			},
		})

		mason_tool_installer.setup({
			-- list of formatters & linters for mason to install
		})
	end,
}
