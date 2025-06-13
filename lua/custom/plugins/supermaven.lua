return {
  'supermaven-inc/supermaven-nvim',
  config = function()
    require('supermaven-nvim').setup {
      -- keymaps = {
      --   accept_suggestion = '<C-y>',
      --   clear_suggestion = '<C-x>',
      --   accept_word = '<C-j>',
      -- },
      opts = {
        disable_inline_completion = true,
      },
    }
  end,
}
