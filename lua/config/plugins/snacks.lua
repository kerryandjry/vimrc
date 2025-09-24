return {
  'folke/snacks.nvim',
  lazy = false,
  ---@type snacks.Config
  opts = {
    picker = { enabled = true },
  },
  config = function()
    -- require 'custom.config.snacks'
    local map = function(key, func, desc)
      vim.keymap.set('n', key, func, { desc = desc })
    end

    -- all keymaps for snacks.picker
    map('<leader>ff', Snacks.picker.smart, 'Smart find file')
    map('<leader>fo', Snacks.picker.recent, 'Find recent file')
    map('<leader>fw', Snacks.picker.grep, 'Find content')
    map('<leader>fh', function()
      Snacks.picker.help { layout = 'dropdown' }
    end, 'Find in help')

    map('<leader>fk', function()
      Snacks.picker.keymaps { layout = 'dropdown' }
    end, 'Find keymap')
  end,
}
