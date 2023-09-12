return {
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"ravenxrz/DAPInstall.nvim",
			config = function()
				local dap_install = require("dap-install")
				dap_install.setup({
					installation_path = vim.fn.stdpath("data") .. "/dapinstall/",
				})
			end,
			"rcarriga/nvim-dap-ui",
			"theHamsta/nvim-dap-virtual-text",
		},

		config = function()
			require("nvim-dap-virtual-text").setup()
			-- default configuration
			local dap_breakpoint = {
				error = {
					text = "🛑",
					texthl = "LspDiagnosticsSignError",
					linehl = "",
					numhl = "",
				},
				rejected = {
					text = "",
					texthl = "LspDiagnosticsSignHint",
					linehl = "",
					numhl = "",
				},
				stopped = {
					text = "⭐️",
					texthl = "LspDiagnosticsSignInformation",
					linehl = "DiagnosticUnderlineInfo",
					numhl = "LspDiagnosticsSignInformation",
				},
			}
			vim.fn.sign_define("DapBreakpoint", dap_breakpoint.error)
			vim.fn.sign_define("DapBreakpointRejected", dap_breakpoint.rejected)
			vim.fn.sign_define("DapStopped", dap_breakpoint.stopped)

			local function config_dapui()
				local dapui, dap = require("dapui"), require("dap")
				local debug_open = function()
					dapui.open()
					vim.api.nvim_command("DapVirtualTextEnable")
					vim.api.nvim_command("NvimTreeClose")
				end

				local debug_close = function()
					dap.repl.close()
					dapui.close()
					vim.api.nvim_command("DapVirtualTextDisable")
				end

				dap.listeners.after.event_initialized["dapui_config"] = function()
					debug_open()
				end
				dap.listeners.before.event_terminated["dapui_config"] = function()
					debug_close()
				end
				dap.listeners.before.event_exited["dapui_config"] = function()
					debug_close()
				end
				dap.listeners.before.event_stopped["dapui_config"] = function()
					debug_close()
				end
			end

			local function config_debuggers()
				require("dap.ext.vscode").load_launchjs(nil, { cppdbg = { "cpp" } })
				require("config.plugins.dap.dap-cpp")
				require("config.plugins.dap.dap-lua")
			end

			config_dapui()
			config_debuggers()
		end,
	},
}
