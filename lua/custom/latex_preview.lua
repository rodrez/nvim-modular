local M = {}

-- State per LaTeX source buffer
local state = {}

local function notify(msg, level)
  vim.notify('[latex-preview] ' .. msg, level or vim.log.levels.INFO)
end

local function ensure_dir(path)
  if vim.fn.isdirectory(path) == 0 then
    vim.fn.mkdir(path, 'p')
  end
end

local function tex_pdf_path(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local vt = vim.b[bufnr] and vim.b[bufnr].vimtex or nil
  local tex_path
  if vt and vt.tex then
    tex_path = vt.tex
  else
    tex_path = vim.api.nvim_buf_get_name(bufnr)
  end
  if tex_path == '' then return nil end

  local root
  local out_dir
  if vt and vt.root then
    root = vt.root
  else
    root = vim.fn.fnamemodify(tex_path, ':h')
  end

  if vt and vt.compiler and vt.compiler.out_dir and vt.compiler.out_dir ~= '' then
    out_dir = vt.compiler.out_dir
  else
    out_dir = ''
  end

  local base = vim.fn.fnamemodify(tex_path, ':t:r')
  local dir = out_dir ~= '' and (root .. '/' .. out_dir) or root
  local pdf = dir .. '/' .. base .. '.pdf'
  return pdf
end

local function output_dir_for(pdf)
  local pdf_dir = vim.fn.fnamemodify(pdf, ':h')
  local base = vim.fn.fnamemodify(pdf, ':t:r')
  local out = pdf_dir .. '/.latex_preview/' .. base
  ensure_dir(out)
  return out
end

local function executable(cmd)
  return vim.fn.executable(cmd) == 1
end

local function system_ok(cmd)
  vim.fn.system(cmd)
  return vim.v.shell_error == 0
end

local function list_pngs(outdir)
  local files = vim.fn.glob(outdir .. '/*.png', true, true)
  table.sort(files, function(a, b)
    return a < b
  end)
  return files
end

local function clean_pngs(outdir)
  local files = list_pngs(outdir)
  for _, f in ipairs(files) do
    pcall(vim.fn.delete, f)
  end
end

-- tmux passthrough detection (for Kitty graphics inside tmux)
local function tmux_passthrough_enabled()
  if not vim.env.TMUX then return true end
  if vim.fn.executable('tmux') ~= 1 then return false end
  local out = vim.fn.system({ 'tmux', 'show', '-g', 'allow-passthrough' })
  if vim.v.shell_error ~= 0 or type(out) ~= 'string' then return false end
  return out:match('on') ~= nil
end

local function convert_pdf_to_pngs(pdf, outdir)
  ensure_dir(outdir)
  clean_pngs(outdir)

  local prefix = outdir .. '/page'
  local pdf_esc = vim.fn.shellescape(pdf)
  local pref_esc = vim.fn.shellescape(prefix)

  local tried = {}

  if executable('pdftoppm') then
    local cmd = string.format('pdftoppm -png -r 150 %s %s', pdf_esc, pref_esc)
    table.insert(tried, cmd)
    if system_ok(cmd) then
      return list_pngs(outdir)
    end
  end

  if executable('magick') then
    local outpat = vim.fn.shellescape(outdir .. '/page-%03d.png')
    local cmd = string.format('magick -density 150 %s -quality 95 %s', pdf_esc, outpat)
    table.insert(tried, cmd)
    if system_ok(cmd) then
      return list_pngs(outdir)
    end
  elseif executable('convert') then
    local outpat = vim.fn.shellescape(outdir .. '/page-%03d.png')
    local cmd = string.format('convert -density 150 %s -quality 95 %s', pdf_esc, outpat)
    table.insert(tried, cmd)
    if system_ok(cmd) then
      return list_pngs(outdir)
    end
  end

  if executable('mutool') then
    local outpat = vim.fn.shellescape(outdir .. '/page-%d.png')
    local cmd = string.format('mutool draw -r 150 -o %s %s', outpat, pdf_esc)
    table.insert(tried, cmd)
    if system_ok(cmd) then
      return list_pngs(outdir)
    end
  end

  if executable('gs') then
    local outpat = vim.fn.shellescape(outdir .. '/page-%03d.png')
    local cmd = string.format('gs -dSAFER -dBATCH -dNOPAUSE -sDEVICE=png16m -r150 -sOutputFile=%s %s', outpat, pdf_esc)
    table.insert(tried, cmd)
    if system_ok(cmd) then
      return list_pngs(outdir)
    end
  end

  notify('Unable to convert PDF to images. Tried:\n' .. table.concat(tried, '\n'), vim.log.levels.ERROR)
  return {}
end

local function build_markdown_lines(images)
  local lines = {}
  for i, img in ipairs(images) do
    table.insert(lines, string.format('![page %d](%s)', i, img))
    table.insert(lines, '')
  end
  if #lines == 0 then
    lines = { '_No pages to display_ (conversion failed?)' }
  end
  return lines
end

local function open_preview_window()
  vim.cmd('vsplit')
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(win, buf)
  vim.bo[buf].filetype = 'markdown'
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
  return buf, win
end

-- Try to open preview automatically if a PDF exists for this buffer
function M.auto_open_if_available(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  -- Don't reopen if it's already open
  if state[bufnr] and state[bufnr].preview_win and vim.api.nvim_win_is_valid(state[bufnr].preview_win) then
    return
  end
  local pdf = tex_pdf_path(bufnr)
  if pdf and vim.fn.filereadable(pdf) == 1 then
    local cur = vim.api.nvim_get_current_win()
    M.open()
    -- Return focus to the tex window
    if vim.api.nvim_win_is_valid(cur) then
      vim.api.nvim_set_current_win(cur)
    end
  end
end

function M.open()
  local texbuf = vim.api.nvim_get_current_buf()
  local pdf = tex_pdf_path(texbuf)
  if not pdf or vim.fn.filereadable(pdf) == 0 then
    notify('PDF not found. Compile first (e.g., :VimtexCompile).', vim.log.levels.WARN)
    return
  end

  -- Warn once per session if tmux passthrough is not enabled
  if vim.env.TMUX and not tmux_passthrough_enabled() and not vim.g.latex_preview_tmux_passthrough_warned then
    vim.g.latex_preview_tmux_passthrough_warned = true
    notify('tmux passthrough is off. Kitty graphics need: set -g allow-passthrough on (tmux 3.4+), then restart tmux.', vim.log.levels.WARN)
  end

  local outdir = output_dir_for(pdf)
  local images = convert_pdf_to_pngs(pdf, outdir)
  if #images == 0 then
    return
  end

  local buf, win = open_preview_window()
  vim.api.nvim_buf_set_name(buf, ('LaTeX Preview: %s'):format(vim.fn.fnamemodify(pdf, ':t')))
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, build_markdown_lines(images))

  -- Track state and auto-refresh on save
  state[texbuf] = { preview_buf = buf, preview_win = win, pdf = pdf, outdir = outdir }

  local group = vim.api.nvim_create_augroup('LatexPreview' .. texbuf, { clear = true })
  vim.api.nvim_create_autocmd('BufWritePost', {
    buffer = texbuf,
    group = group,
    callback = function()
      -- Let vimtex compile, then refresh after a tiny delay
      vim.defer_fn(function()
        M.refresh(texbuf)
      end, 200)
    end,
  })
end

function M.refresh(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local st = state[bufnr]
  if not st then return end
  if vim.fn.filereadable(st.pdf) == 0 then
    notify('PDF not found. Compile first.', vim.log.levels.WARN)
    return
  end
  local images = convert_pdf_to_pngs(st.pdf, st.outdir)
  if #images == 0 then return end
  if st.preview_buf and vim.api.nvim_buf_is_valid(st.preview_buf) then
    vim.api.nvim_buf_set_lines(st.preview_buf, 0, -1, false, build_markdown_lines(images))
  end
end

function M.close()
  local texbuf = vim.api.nvim_get_current_buf()
  local st = state[texbuf]
  if not st then return end
  if st.preview_win and vim.api.nvim_win_is_valid(st.preview_win) then
    pcall(vim.api.nvim_win_close, st.preview_win, true)
  end
  state[texbuf] = nil
end

function M.toggle()
  local texbuf = vim.api.nvim_get_current_buf()
  local st = state[texbuf]
  if st and st.preview_win and vim.api.nvim_win_is_valid(st.preview_win) then
    M.close()
  else
    M.open()
  end
end

local function move_to_image_line(direction, texbuf)
  texbuf = texbuf or vim.api.nvim_get_current_buf()
  local st = state[texbuf]
  if not st or not (st.preview_win and vim.api.nvim_win_is_valid(st.preview_win)) then return end
  local win = st.preview_win
  local buf = st.preview_buf
  if not vim.api.nvim_buf_is_valid(buf) then return end

  local row = (vim.api.nvim_win_get_cursor(win))[1]
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  local start_i, stop_i, step
  if direction == 'next' then
    start_i, stop_i, step = row + 1, #lines, 1
  else
    start_i, stop_i, step = row - 1, 1, -1
  end

  local i = start_i
  while (direction == 'next' and i <= stop_i) or (direction == 'prev' and i >= stop_i) do
    if lines[i] and lines[i]:match('^%!%[page') then
      vim.api.nvim_win_set_cursor(win, { i, 0 })
      return
    end
    i = i + step
  end
end

function M.goto_next_page(buf)
  move_to_image_line('next', buf)
end

function M.goto_prev_page(buf)
  move_to_image_line('prev', buf)
end

return M
