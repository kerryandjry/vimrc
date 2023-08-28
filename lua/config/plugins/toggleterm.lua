return {
    "akinsho/toggleterm.nvim",
    version = "*", 
    config = function()
        require("toggleterm").setup()
        local Terminal = require("toggleterm.terminal").Terminal
        local lazygit = Terminal:new({
            cmd = 'lazygit',
            direction = 'float',
        })
        function lazygit_toggle()
            lazygit:toggle()
        end
        vim.api.nvim_set_keymap("n", "<c-g>", "<Cmd>lua lazygit_toggle()<CR>", {noremap = true, silent = true})

        local yazi = Terminal:new({
            cmd = 'yazi',
            direction = 'float',
        })
        function yazi_toggle()
            yazi:toggle()
        end
        vim.api.nvim_set_keymap("n", "<c-y>", "<Cmd>lua yazi_toggle()<CR>", {noremap = true, silent = true})
    end,
}
