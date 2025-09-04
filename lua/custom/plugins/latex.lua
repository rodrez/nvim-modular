return {
  'lervag/vimtex',
  -- Load VimTeX only for LaTeX-related files
  ft = { 'tex', 'plaintex', 'latex' },
  init = function()
    -- Choose a sensible PDF viewer per OS
    local sys = (vim.loop and vim.loop.os_uname and vim.loop.os_uname().sysname) or ''
    if sys == 'Darwin' then
      -- macOS: use Skim if installed
      vim.g.vimtex_view_method = 'skim'
      vim.g.vimtex_view_skim_sync = 1
      vim.g.vimtex_view_skim_reading_bar = 0
    else
      -- Linux: default to zathura (common on Linux)
      vim.g.vimtex_view_method = 'zathura'
    end

    -- Default to in-editor preview; do not auto-open external viewer
    vim.g.vimtex_view_automatic = 0

    -- Keep quickfix closed by default; mappings enabled
    vim.g.vimtex_quickfix_mode = 0
    vim.g.vimtex_mappings_enabled = 1
  end,
}
