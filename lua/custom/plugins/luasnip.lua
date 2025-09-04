return {
  'L3MON4D3/LuaSnip',
  event = 'InsertEnter',
  dependencies = { 'rafamadriz/friendly-snippets' },
  config = function()
    local ls = require 'luasnip'

    -- Basic LuaSnip settings
    ls.config.set_config {
      history = true,
      updateevents = 'TextChanged,TextChangedI',
      enable_autosnippets = false,
      delete_check_events = 'TextChanged',
      region_check_events = 'CursorHold,InsertLeave',
    }

    -- Load VSCode-format snippets from friendly-snippets
    require('luasnip.loaders.from_vscode').lazy_load()

    -- Load local Lua snippets from this repo (lua/snippets/**)
    local paths = { vim.fn.stdpath('config') .. '/lua/snippets' }
    require('luasnip.loaders.from_lua').lazy_load { paths = paths }

    -- Safe, non-conflicting keymaps for jumping inside snippets
    vim.keymap.set({ 'i', 's' }, '<C-j>', function()
      if ls.jumpable(1) then ls.jump(1) end
    end, { desc = 'LuaSnip jump forward' })

    vim.keymap.set({ 'i', 's' }, '<C-k>', function()
      if ls.jumpable(-1) then ls.jump(-1) end
    end, { desc = 'LuaSnip jump backward' })

    vim.keymap.set({ 'i', 's' }, '<C-l>', function()
      if ls.choice_active() then ls.change_choice(1) end
    end, { desc = 'LuaSnip next choice' })
  end,
}

