local M = {}

-- Configuration
local config = {
  python_cmd = vim.fn.stdpath('config') .. '/.venv/bin/python',
  bridge_script = vim.fn.stdpath('config') .. '/scripts/jupyter_bridge.py',
  connection_file = nil,
  timeout = 30,
  cell_markers = {
    start = '# %%',
    ['end'] = '# %%',
  },
  output_prefix = '# ',
  plot_prefix = '# OUTPUT-PLOT: ',
  error_prefix = '# ERROR: ',
  keymaps = {
    execute = '<leader>je',
    view_plot = '<leader>jp',
    clear_output = '<leader>jc',
    restart_kernel = '<leader>jr',
  }
}

-- State management
local state = {
  kernel_process = nil,
  last_execution_line = nil,
}

-- Utility functions
local function get_visual_selection()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local start_line = start_pos[2] - 1
  local end_line = end_pos[2] - 1
  
  local lines = vim.api.nvim_buf_get_lines(0, start_line, end_line + 1, false)
  return table.concat(lines, '\n'), start_line, end_line
end

local function get_current_cell()
  local current_line = vim.api.nvim_win_get_cursor(0)[1] - 1
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  
  -- Find cell boundaries
  local cell_start = 0
  local cell_end = #lines - 1
  
  -- Look backwards for cell start
  for i = current_line, 0, -1 do
    if lines[i + 1] and lines[i + 1]:match('^' .. vim.pesc(config.cell_markers.start)) then
      cell_start = i + 1
      break
    end
  end
 
  -- Look forwards for cell end
  for i = current_line + 1, #lines - 1 do
     if lines[i + 1] and lines[i + 1]:match('^' .. vim.pesc(config.cell_markers['end'])) then      cell_end = i - 1
      break
    end
  end
  
  -- Extract cell content (excluding markers and previous output)
  local cell_lines = {}
  local output_start = nil
  
  for i = cell_start, cell_end do
    local line = lines[i + 1] or ""
    
    -- Skip cell markers
    if line:match('^' .. vim.pesc(config.cell_markers.start)) or 
       line:match('^' .. vim.pesc(config.cell_markers['end'])) then
      goto continue
    end
    
    -- Check if this is start of previous output
    if line:match('^' .. vim.pesc(config.output_prefix)) or 
       line:match('^' .. vim.pesc(config.plot_prefix)) or
       line:match('^' .. vim.pesc(config.error_prefix)) then
      output_start = i
      break
    end
    
    -- Add non-empty, non-comment lines to cell
    if line:match('%S') and not line:match('^%s*#') then
      table.insert(cell_lines, line)
    end
    
    ::continue::
  end
  
  local code = table.concat(cell_lines, '\n')
  local insert_line = output_start or (cell_end + 1)
  
  return code, cell_start, cell_end, insert_line
end

local function clear_cell_output(start_line, end_line)
  local lines = vim.api.nvim_buf_get_lines(0, start_line, end_line + 1, false)
  local new_lines = {}
  
  for _, line in ipairs(lines) do
    -- Keep lines that are not output
    if not (line:match('^' .. vim.pesc(config.output_prefix)) or 
            line:match('^' .. vim.pesc(config.plot_prefix)) or
            line:match('^' .. vim.pesc(config.error_prefix))) then
      table.insert(new_lines, line)
    end
  end
  
  vim.api.nvim_buf_set_lines(0, start_line, end_line + 1, false, new_lines)
  return #lines - #new_lines  -- Number of lines removed
end

local function insert_output(output_text, insert_line)
  if not output_text or output_text == "" then
    return
  end
  
  local output_lines = vim.split(output_text, '\n')
  
  -- Filter out empty lines and add prefix
  local filtered_lines = {}
  for _, line in ipairs(output_lines) do
    if line:match('%S') then
      table.insert(filtered_lines, config.output_prefix .. line)
    end
  end
  
  if #filtered_lines > 0 then
    vim.api.nvim_buf_set_lines(0, insert_line, insert_line, false, filtered_lines)
  end
end

-- Core execution function
function M.execute_cell()
  local code, cell_start, cell_end, insert_line = get_current_cell()
  
  if not code or code:match('^%s*$') then
    vim.notify("No code found in current cell", vim.log.levels.WARN)
    return
  end
  
  -- Clear previous output
  local lines_removed = clear_cell_output(cell_start, cell_end)
  insert_line = insert_line - lines_removed
  
  -- Show execution indicator
  vim.notify("Executing cell...", vim.log.levels.INFO)
  
  -- Build command
  local cmd = {
    config.python_cmd,
    config.bridge_script,
    '--timeout', tostring(config.timeout),
    '--stream'  -- Enable streaming mode
  }
  
  if config.connection_file then
    table.insert(cmd, '--connection-file')
    table.insert(cmd, config.connection_file)
  end
  
  table.insert(cmd, code)
  
  -- Add output start marker immediately (without affecting undo history)
  local start_marker = {
    config.output_prefix .. "=" .. string.rep("=", 50),
    config.output_prefix .. "📊 OUTPUT START",
    config.output_prefix .. "=" .. string.rep("=", 50)
  }
  
  -- Start a new undo block for all output
  vim.cmd('undojoin | startinsert | stopinsert')  -- Ensure we have something to join with
  vim.api.nvim_buf_set_lines(0, insert_line, insert_line, false, start_marker)
  local current_insert_line = insert_line + #start_marker
  
  -- Execute asynchronously with real-time streaming
  vim.fn.jobstart(cmd, {
    stdout_buffered = false,  -- Enable real-time streaming
    stderr_buffered = false,
    on_stdout = function(_, data)
      if data and #data > 0 then
        vim.schedule(function()
          local output_lines = {}
          for _, line in ipairs(data) do
            if line and line ~= "" then
              table.insert(output_lines, config.output_prefix .. line)
            end
          end
          
          if #output_lines > 0 then
            -- Join with previous undo block to avoid polluting undo history
            pcall(vim.cmd, 'undojoin')
            vim.api.nvim_buf_set_lines(0, current_insert_line, current_insert_line, false, output_lines)
            current_insert_line = current_insert_line + #output_lines
            -- Refresh syntax highlighting
            vim.cmd('syntax sync fromstart')
          end
        end)
      end
    end,
    on_stderr = function(_, data)
      if data and #data > 0 then
        local error_msg = table.concat(data, '\n')
        vim.schedule(function()
          -- Filter out warnings, only show actual errors
          if not error_msg:match("WARNING:") then
            vim.notify("Execution error: " .. error_msg, vim.log.levels.ERROR)
          end
        end)
      end
    end,
    on_exit = function(_, exit_code)
      vim.schedule(function()
        -- Add output end marker (join with undo block)
        local end_marker = {
          config.output_prefix .. "=" .. string.rep("=", 50),
          config.output_prefix .. "📊 OUTPUT END",
          config.output_prefix .. "=" .. string.rep("=", 50)
        }
        pcall(vim.cmd, 'undojoin')
        vim.api.nvim_buf_set_lines(0, current_insert_line, current_insert_line, false, end_marker)
        
        if exit_code == 0 then
          vim.notify("Cell executed successfully", vim.log.levels.INFO)
        else
          vim.notify("Bridge script failed with exit code: " .. exit_code, vim.log.levels.ERROR)
        end
      end)
    end
  })
  
  state.last_execution_line = insert_line
end

-- Execute visual selection
function M.execute_selection()
  local code, start_line, end_line = get_visual_selection()
  
  if not code or code:match('^%s*$') then
    vim.notify("No code selected", vim.log.levels.WARN)
    return
  end
  
  -- Show execution indicator
  vim.notify("Executing selection...", vim.log.levels.INFO)
  
  -- Build command
  local cmd = {
    config.python_cmd,
    config.bridge_script,
    '--timeout', tostring(config.timeout),
    '--stream'  -- Enable streaming mode
  }
  
  if config.connection_file then
    table.insert(cmd, '--connection-file')
    table.insert(cmd, config.connection_file)
  end
  
  table.insert(cmd, code)
  
  -- Execute and insert output after selection
  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data and #data > 0 then
        local output = table.concat(data, '\n')
        vim.schedule(function()
          insert_output(output, end_line + 1)
          -- Refresh syntax highlighting after inserting output
          vim.cmd('syntax sync fromstart')
          vim.notify("Selection executed successfully", vim.log.levels.INFO)
        end)
      end
    end,
    on_stderr = function(_, data)
      if data and #data > 0 then
        local error_msg = table.concat(data, '\n')
        vim.schedule(function()
          -- Filter out warnings, only show actual errors
          if not error_msg:match("WARNING:") then
            vim.notify("Execution error: " .. error_msg, vim.log.levels.ERROR)
          end
        end)
      end
    end
  })
end

-- Plot viewing function
function M.view_plot()
  local current_line = vim.api.nvim_get_current_line()
  local plot_path = current_line:match(config.plot_prefix .. '(.+)')
  
  if not plot_path then
    vim.notify("No plot found on current line", vim.log.levels.WARN)
    return
  end
  
  -- Check if plot file exists
  if vim.fn.filereadable(plot_path) == 0 then
    vim.notify("Plot file not found: " .. plot_path, vim.log.levels.ERROR)
    return
  end
  
  -- Try different image viewers
  local viewers = {'viu', 'imgcat', 'feh', 'open'}
  local viewer_found = false
  
  for _, viewer in ipairs(viewers) do
    if vim.fn.executable(viewer) == 1 then
      if viewer == 'viu' then
        -- Use floating terminal for viu
        local buf = vim.api.nvim_create_buf(false, true)
        local width = math.floor(vim.o.columns * 0.8)
        local height = math.floor(vim.o.lines * 0.8)
        local row = math.floor((vim.o.lines - height) / 2)
        local col = math.floor((vim.o.columns - width) / 2)
        
        local win = vim.api.nvim_open_win(buf, true, {
          relative = 'editor',
          width = width,
          height = height,
          row = row,
          col = col,
          style = 'minimal',
          border = 'rounded',
          title = ' Plot Viewer ',
          title_pos = 'center'
        })
        
        -- Set up terminal
        vim.fn.termopen(viewer .. ' ' .. vim.fn.shellescape(plot_path), {
          on_exit = function()
            vim.schedule(function()
              if vim.api.nvim_win_is_valid(win) then
                vim.api.nvim_win_close(win, true)
              end
            end)
          end
        })
        
        -- Set keymap to close window
        vim.api.nvim_buf_set_keymap(buf, 'n', 'q', '<cmd>close<cr>', {noremap = true, silent = true})
        vim.api.nvim_buf_set_keymap(buf, 't', '<Esc>', '<C-\\><C-n><cmd>close<cr>', {noremap = true, silent = true})
        
      else
        -- Use system viewer
        vim.fn.jobstart({viewer, plot_path}, {detach = true})
      end
      
      viewer_found = true
      break
    end
  end
  
  if not viewer_found then
    vim.notify("No image viewer found. Install viu, imgcat, feh, or similar.", vim.log.levels.ERROR)
  end
end

-- Clear all output in current cell
function M.clear_cell_output()
  local _, cell_start, cell_end = get_current_cell()
  clear_cell_output(cell_start, cell_end)
  vim.notify("Cell output cleared", vim.log.levels.INFO)
end

-- Configuration functions
function M.set_connection_file(file_path)
  if file_path and vim.fn.filereadable(file_path) == 1 then
    config.connection_file = file_path
    vim.notify("Connection file set to: " .. file_path, vim.log.levels.INFO)
  else
    vim.notify("Connection file not found: " .. (file_path or "nil"), vim.log.levels.ERROR)
  end
end

function M.get_config()
  return config
end

function M.setup(user_config)
  -- Merge user config
  if user_config then
    config = vim.tbl_deep_extend('force', config, user_config)
  end
  
  -- Check if Python executable exists
  if vim.fn.executable(config.python_cmd) == 0 then
    vim.notify("Python executable not found: " .. config.python_cmd .. ". Run 'uv sync' first.", vim.log.levels.ERROR)
    return
  end
  
  -- Check if bridge script exists
  if vim.fn.filereadable(config.bridge_script) == 0 then
    vim.notify("Jupyter bridge script not found: " .. config.bridge_script, vim.log.levels.ERROR)
    return
  end
  
  -- Set up custom highlighting for Jupyter output
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "python",
    callback = function()
      -- Define custom highlight groups that integrate with the current theme
      local colors = {
        output = vim.api.nvim_get_hl(0, {name = "Comment"}),
        error = vim.api.nvim_get_hl(0, {name = "ErrorMsg"}),
        plot = vim.api.nvim_get_hl(0, {name = "String"}),
      }
      
      -- Customize the colors slightly for better distinction
      if colors.output.fg then
        colors.output.fg = colors.output.fg
        colors.output.italic = true
      end
      
      if colors.error.fg then
        colors.error.bold = true
      end
      
      if colors.plot.fg then
        colors.plot.bold = true
      end
      
      -- Set the highlight groups
      vim.api.nvim_set_hl(0, "JupyterOutput", colors.output)
      vim.api.nvim_set_hl(0, "JupyterError", colors.error)
      vim.api.nvim_set_hl(0, "JupyterPlot", colors.plot)
    end,
  })
  
  -- Set up keymaps
  local opts = {noremap = true, silent = true}
  
  vim.keymap.set('n', config.keymaps.execute, M.execute_cell, 
    vim.tbl_extend('force', opts, {desc = 'Execute Jupyter cell'}))
  
  vim.keymap.set('v', config.keymaps.execute, M.execute_selection, 
    vim.tbl_extend('force', opts, {desc = 'Execute Jupyter selection'}))
  
  vim.keymap.set('n', config.keymaps.view_plot, M.view_plot, 
    vim.tbl_extend('force', opts, {desc = 'View plot on current line'}))
  
  vim.keymap.set('n', config.keymaps.clear_output, M.clear_cell_output, 
    vim.tbl_extend('force', opts, {desc = 'Clear cell output'}))
  
  -- Set up commands
  vim.api.nvim_create_user_command('JupyterExecuteCell', M.execute_cell, {})
  vim.api.nvim_create_user_command('JupyterViewPlot', M.view_plot, {})
  vim.api.nvim_create_user_command('JupyterClearOutput', M.clear_cell_output, {})
  vim.api.nvim_create_user_command('JupyterSetConnection', function(opts)
    M.set_connection_file(opts.args)
  end, {nargs = 1, complete = 'file'})
  
  vim.notify("Jupyter Inline plugin loaded", vim.log.levels.INFO)
end

return {
  'nvim-jupyter-inline',
  dir = vim.fn.stdpath('config'),
  config = function()
    M.setup()
  end,
  keys = {
    {'<leader>je', desc = 'Execute Jupyter cell/selection'},
    {'<leader>jp', desc = 'View plot'},
    {'<leader>jc', desc = 'Clear cell output'},
  },
  cmd = {
    'JupyterExecuteCell',
    'JupyterViewPlot', 
    'JupyterClearOutput',
    'JupyterSetConnection'
  }
}
