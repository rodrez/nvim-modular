return {
  {
    dir = '~/.config/nvim/lua/ai/',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      require('ai').setup {
        provider = 'openai',
        openai = {
          token = os.getenv('OPENAI_API_KEY'),
          model = 'gpt-4o-mini',
          max_tokens = 4096,
          temperature = 0.1,
        },
      }

      vim.api.nvim_create_user_command('AiStreamSelection', function()
        require('ai').stream_selection()
      end, {
        desc = 'Stream the current visual selection to the AI endpoint',
      })
    end,
  },
}
