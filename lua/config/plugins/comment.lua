return {
	"numToStr/Comment.nvim",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		require("Comment").setup()
		vim.keymap.set("x", "gcc", "<Plug>(comment_toggle_linewise_visual)", {
			remap = true,
			desc = "Comment selected lines",
		})
	end,
}
