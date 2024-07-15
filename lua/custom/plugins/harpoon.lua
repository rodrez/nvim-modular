return {
  'ThePrimeagen/harpoon',
  config = function()
    local harpoon = require 'harpoon'

    vim.keymap.set('n', '<leader>a', function()
      harpoon:list():add()
    end)
    vim.keymap.set('n', '<C-e>', function()
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end)

    -- Set <C-h>, <C-t>, <C-n>, and <C-s> be my shortcuts to moving to the files
    for i, char in ipairs { 'h', 't', 'n', 's' } do
      vim.keymap.set('n', string.format('<C-%s>', char), function()
        harpoon:list():select(i)
      end)
    end
  end,
}
