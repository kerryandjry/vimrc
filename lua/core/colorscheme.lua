local status, _ = pcall(vim.cmd, "colorscheme gruvbox")
if not status then
	print("Colorscheme not found!") -- print error if colorscheme not installed
	return
end

if vim.g.neovide then
	local neovide = require("neovide")
	neovide.init()
end
