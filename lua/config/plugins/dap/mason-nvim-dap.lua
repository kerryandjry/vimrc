return {
	"jay-babu/mason-nvim-dap.nvim",
	event = "VeryLazy",
	dependencies = {
		"williamboman/mason.nvim",
		"mfussenegger/nvim-dap",
	},
	handler = {
		python = function(config)
			config.adapters = {
				type = "executable",
				args = {
					"-m",
					"debugpy.adapter",
				},
			}
			require("mason-nvim-dap").default_setup(config) -- don't forget this!
		end,
	},
}
