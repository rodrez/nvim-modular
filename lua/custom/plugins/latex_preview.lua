return {
  -- Render images (used to show PDF pages converted to PNG)
  '3rd/image.nvim',
  -- Load on VeryLazy so the markdown preview buffer can render immediately
  event = 'VeryLazy',
  opts = {
    -- Ghostty supports the Kitty graphics protocol; force that backend
    backend = 'kitty',
    integrations = {
      -- Leverage markdown integration so we can render a list of PNGs easily
      markdown = {
        enabled = true,
        clear_in_insert_mode = false,
        download_remote_images = false,
        only_render_image_at_cursor = false,
        filetypes = { 'markdown' },
      },
    },
    editor_only_render_when_focused = false,
  },
  config = function(_, opts)
    -- If inside tmux without passthrough, skip initializing kitty backend to avoid errors.
    local in_tmux = vim.env.TMUX ~= nil
    local function tmux_passthrough_enabled()
      if not in_tmux then return true end
      if vim.fn.executable('tmux') ~= 1 then return false end
      local out = vim.fn.system({ 'tmux', 'show', '-g', 'allow-passthrough' })
      return vim.v.shell_error == 0 and type(out) == 'string' and out:match('on') ~= nil
    end

    if in_tmux and (opts.backend == 'kitty' or opts.backend == nil) and not tmux_passthrough_enabled() then
      vim.g.image_tmux_passthrough_missing = true
      -- Do not call require('image').setup to prevent backend init error.
    else
      -- Initialize image.nvim
      require('image').setup(opts)
    end

    -- No global warning here; LaTeX preview shows a one-time reminder instead

    -- Health command to inspect environment and integration status
    local function tmux_info()
      local info = { in_tmux = vim.env.TMUX ~= nil, version = 'unknown', passthrough = 'unknown' }
      if not info.in_tmux then return info end
      if vim.fn.executable('tmux') == 1 then
        local ver = vim.fn.system({ 'tmux', '-V' })
        if vim.v.shell_error == 0 and type(ver) == 'string' then
          info.version = ver:gsub('%s+$', '')
        end
        local show = vim.fn.system({ 'tmux', 'show', '-g', 'allow-passthrough' })
        if vim.v.shell_error == 0 and type(show) == 'string' then
          info.passthrough = show:match('on') and 'on' or (show:match('off') and 'off' or 'unknown')
        end
      end
      return info
    end

    local function term_info()
      local tp = vim.env.TERM_PROGRAM or ''
      local tpv = vim.env.TERM_PROGRAM_VERSION or ''
      local term = (tp ~= '' and (tp .. (tpv ~= '' and (' ' .. tpv) or ''))) or (vim.env.TERM or 'unknown')
      local ghostty = tp:lower():find('ghostty') ~= nil
      local kitty = tp:lower():find('kitty') ~= nil
      local wez = tp:lower():find('wezterm') ~= nil
      local iterm = tp:lower():find('iterm') ~= nil
      return { term = term, is_ghostty = ghostty, is_kitty = kitty, is_wezterm = wez, is_iterm = iterm }
    end

    vim.api.nvim_create_user_command('ImageHealth', function()
      local tmx = tmux_info()
      local term = term_info()
      local backend = opts.backend or 'auto'
      local md_enabled = opts.integrations and opts.integrations.markdown and opts.integrations.markdown.enabled

      local lines = {}
      table.insert(lines, 'image.nvim health')
      table.insert(lines, '----------------------------------------')
      table.insert(lines, ('Terminal: %s'):format(term.term))
      table.insert(lines, ('Backend: %s'):format(backend))
      table.insert(lines, ('Markdown integration: %s'):format(md_enabled and 'enabled' or 'disabled'))
      table.insert(lines, ('In tmux: %s'):format(tmx.in_tmux and 'yes' or 'no'))
      if tmx.in_tmux then
        table.insert(lines, ('tmux version: %s'):format(tmx.version))
        table.insert(lines, ('tmux allow-passthrough: %s'):format(tmx.passthrough))
      end

      -- Guidance
      if backend == 'kitty' then
        if tmx.in_tmux and tmx.passthrough ~= 'on' then
          table.insert(lines, 'Note: Enable Kitty graphics passthrough in tmux: set -g allow-passthrough on (tmux 3.4+)')
        end
        if not (term.is_ghostty or term.is_kitty or term.is_wezterm or term.is_iterm) then
          table.insert(lines, 'Note: Kitty graphics require a compatible terminal (Ghostty, Kitty, WezTerm, iTerm2).')
        end
      end

      vim.schedule(function()
        vim.notify(table.concat(lines, '\n'))
      end)
    end, { desc = 'Show image.nvim rendering health and environment status' })

    vim.api.nvim_create_user_command('LatexPreviewHealth', function()
      vim.cmd('ImageHealth')
    end, { desc = 'Alias to ImageHealth for LaTeX preview' })
  end,
  init = function()
    -- Buffer-local keymaps for LaTeX buffers
    vim.api.nvim_create_autocmd('FileType', {
      pattern = { 'tex', 'plaintex', 'latex' },
      callback = function(ev)
        local lp = require('custom.latex_preview')
        local map = function(lhs, rhs, desc)
          vim.keymap.set('n', lhs, rhs, { buffer = ev.buf, desc = desc })
        end

        map('<leader>lp', lp.toggle, 'LaTeX: Toggle in-editor preview')
        map('<leader>lr', lp.refresh, 'LaTeX: Refresh preview')
        map('<leader>ln', function() lp.goto_next_page(ev.buf) end, 'LaTeX: Next page')
        map('<leader>lb', function() lp.goto_prev_page(ev.buf) end, 'LaTeX: Previous page')

        -- Open external viewer on demand
        map('<leader>lv', '<cmd>VimtexView<cr>', 'LaTeX: Open external viewer')

        -- Auto-open in-editor preview if PDF already exists
        vim.schedule(function()
          pcall(function()
            lp.auto_open_if_available(ev.buf)
          end)
        end)

        -- After each save, try opening (if now available) and refresh
        local grp = vim.api.nvim_create_augroup('LatexPreviewFileBuf' .. ev.buf, { clear = true })
        vim.api.nvim_create_autocmd('BufWritePost', {
          buffer = ev.buf,
          group = grp,
          callback = function()
            vim.defer_fn(function()
              pcall(lp.auto_open_if_available, ev.buf)
              pcall(lp.refresh, ev.buf)
            end, 250)
          end,
        })
      end,
    })
  end,
}
