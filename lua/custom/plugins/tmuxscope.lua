return {
  'maskdotdev/tmuxscope',
  event = 'VeryLazy',
  dependencies = {
    'nvim-telescope/telescope.nvim',
  },
  config = function()
    require('telescope').load_extension 'tmuxscope'
  end,
}
