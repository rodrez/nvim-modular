return {
  'maskdotdev/tmuxscope',
  dependencies = {
    'nvim-telescope/telescope.nvim',
  },
  config = function()
    require('telescope').load_extension 'tmuxscope'
  end,
}
