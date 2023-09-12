return {
	{
		"rcarriga/nvim-dap-ui",
		config = function()
			require("dapui").setup({
				icons = { expanded = "▾", collapsed = "▸" },
				mappings = {
					-- Use a table to apply multiple mappings
					expand = { "o", "<2-LeftMouse>", "<CR>" },
					open = "O",
					remove = "d",
					edit = "e",
					repl = "r",
					toggle = "t",
				},
				layouts = {
					{
						elements = {
							"scopes",
						},
						size = 40,
						position = "left",
					},
					{
						elements = {
							-- 'stacks',
							"breakpoints",
							"watches",
						},
						size = 40,
						position = "right",
					},
					{
						elements = {
							"console",
						},
						size = 5,
						position = "top",
					},
					{
						elements = {
							"repl",
						},
						size = 12,
						position = "bottom",
					},
				},
				floating = {
					max_height = nil, -- These can be integers or a float between 0 and 1.
					max_width = nil, -- Floats will be treated as percentage of your screen.
					border = "single", -- Border style. Can be "single", "double" or "rounded"
					mappings = {
						close = { "q", "<Esc>" },
					},
				},
				windows = { indent = 1 },
			})
		end,
	},
}
