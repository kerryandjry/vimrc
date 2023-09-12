return {
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"rcarriga/nvim-dap-ui",
			"thehamsta/nvim-dap-virtual-text",
		},

		config = function()
			require("nvim-dap-virtual-text").setup()
			-- default configuration
			local function config_dap()
				local dap_breakpoint = {
					error = {
						text = "🛑",
						texthl = "lspdiagnosticssignerror",
						linehl = "",
						numhl = "",
					},
					rejected = {
						text = "",
						texthl = "lspdiagnosticssignhint",
						linehl = "",
						numhl = "",
					},
					stopped = {
						text = "⭐️",
						texthl = "lspdiagnosticssigninformation",
						linehl = "diagnosticunderlineinfo",
						numhl = "lspdiagnosticssigninformation",
					},
				}

				vim.fn.sign_define("dapbreakpoint", dap_breakpoint.error)
				vim.fn.sign_define("dapbreakpointrejected", dap_breakpoint.rejected)
				vim.fn.sign_define("dapstopped", dap_breakpoint.stopped)
			end

			local function os_capture(cmd, raw)
				local f = assert(io.popen(cmd, "r"))
				local s = assert(f:read("*a"))
				f:close()
				if raw then
					return s
				end
				s = string.gsub(s, "^%s+", "")
				s = string.gsub(s, "%s+$", "")
				s = string.gsub(s, "[\n\r]+", " ")
				return s
			end

			local function file_exists(name)
				local f = io.open(name, "r")
				if f ~= nil then
					io.close(f)
					return true
				else
					return false
				end
			end

			local dap, dapui = require("dap"), require("dapui")
			local function config_dapui()
				local debug_open = function()
					dapui.open()
					vim.api.nvim_command("DapVirtualTextEnable")
					vim.api.nvim_command("NvimTreeClose")
				end
				local debug_close = function()
					dap.repl.close()
					dapui.close()
					vim.api.nvim_command("DapVirtualTextDisable")
					-- vim.api.nvim_command("bdelete! term:")   -- close debug temrinal
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
				dap.listeners.before.disconnect["dapui_config"] = function()
					debug_close()
				end
			end

			dap.defaults.fallback.switchbuf = true

			dap.adapters.cpptools = {
				type = "server",
				port = "${port}",
				executable = {
					command = vim.fn.stdpath("data")
						.. "/mason/packages/cpptools/extension/debugAdapters/bin/OpenDebugAD7",
					args = { "--port", "${port}" },
					-- command = os_capture('which sh'),
					-- args = {"-c", "codelldb --port ${port}"},
					-- On windows you may have to uncomment this:
					-- detached = false,
				},
			}

			dap.configurations.cpp = {
				{
					name = "Launch file",
					type = "cpptools",
					request = "launch",
					program = function()
						-- local exepath = os_capture('sh -c "$SHELL -ic cmxp"')
						-- if file_exists(exepath) then
						-- 	return exepath
						-- else
						return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
						-- end
					end,
					cwd = "${workspaceFolder}",
					stopOnEntry = false,
				},
			}
			dap.configurations.c = dap.configurations.cpp
			dap.configurations.rust = dap.configurations.cpp

			dap.adapters.python = function(cb, config)
				if config.request == "attach" then
					---@diagnostic disable-next-line: undefined-field
					local port = (config.connect or config).port
					---@diagnostic disable-next-line: undefined-field
					local host = (config.connect or config).host or "127.0.0.1"
					cb({
						type = "server",
						port = assert(port, "`connect.port` is required for a python `attach` configuration"),
						host = host,
						options = {
							source_filetype = "python",
						},
					})
				else
					cb({
						type = "executable",
						command = vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python",
						args = { "-m", "debugpy.adapter" },
						options = {
							source_filetype = "python",
						},
					})
				end
			end

			dap.configurations.python = {
				{
					type = "python",
					request = "launch",
					name = "Launch file",
					program = "${file}",
					pythonPath = function()
						-- return os_capture("which python")
						return "/usr/bin/python3"
					end,
				},
			}

			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated["dapui_config"] = function()
				dapui.close()
			end
			dap.listeners.before.event_exited["dapui_config"] = function()
				dapui.close()
			end

			config_dap()
			config_dapui()
		end,
	},
}
