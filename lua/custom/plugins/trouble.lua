return {
    'folke/trouble.nvim',
    opts= {},
    cmd = "Trouble",
    keys = {
      {
        '<leader>tt',
        '<cmd>Trouble diagnostics toggle filter.buf=0<cr>',
        desc = "[T]rouble diagnostics current buffer "
      },
      {
        '<leader>tT',
        '<cmd>Trouble diagnostics toggle<cr>',
        desc = "[T]rouble diagnostics"
      },
      {
        '[t',
        '<cmd>Trouble diagnostics next<cr>',
        desc = "[T]rouble diagnostics next"
      },
      {
        ']t',
        '<cmd>Trouble diagnostics prev<cr>',
        desc = "[T]rouble diagnostics previous"
      }
    },
    modes = {
      preview_float = {
        mode = "diagnostics",
        preview = {
          type = "float",
          relative = "editor",
          border = "rounded",
          title = "Preview",
          title_pos = "center",
          position = { 0, -2 },
          size = { width = 0.3, height = 0.3 },
          zindex = 200,
        },
      },
    }
  }
