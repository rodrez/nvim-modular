return {
  'sindrets/diffview.nvim',
  config = {
    vim.keymap.set('n', '<leader>dv', ':DiffviewOpen<CR>', { desc = '[D]iff[V]iew Open' }),
    vim.keymap.set('n', '<leader>dx', ':DiffviewClose<CR>', { desc = '[D]iffview [X] close' }),
    vim.keymap.set('n', '<leader>df', ':DiffviewRefresh<CR>', { desc = '[D]iffview re[F]resh' }),
  },
}
