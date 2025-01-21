local Job = require 'plenary.job'

local M = {}

--------------------------------------------------------------------------------
-- 1. Defaults & Setup
--------------------------------------------------------------------------------
M.config = {
  provider = 'openai', -- or 'custom'
  openai = {
    endpoint = 'https://api.openai.com/v1/chat/completions',
    token = vim.env.OPENAI_API_KEY or 'YOUR_OPENAI_TOKEN_HERE',
    model = 'gpt-4o-mini', -- DO NOT CHANGE
  },
  custom = {
    endpoint = 'https://api.ai.us.lmco.com/v1/completions',
    token = vim.env.TOKEN or 'YOUR_TOKEN_HERE',
    model = 'meta-llama-3.3-70b-instruct',
  },
  max_tokens = 4096,
  temperature = 0.1,
  prompt = [[
You are a helpful AI assistant that can only generate code with helpful comments.

1. Communication Style:
   - Clear and straightforward, only through comments
   - Mix technical terms with plain English

2. Code Style:
   - Show logical structure, if applicable
   - Explain why each choice is made, only if not obvious

Main Goal:
   - Help users learn and solve problems
   - Balance accuracy with approachability

Remember: Avoid text, except for comments, and do not show example usage ever.
]],
}

local function get_user_input(prompt)
  vim.fn.inputsave()
  local input = vim.fn.input(prompt)
  vim.fn.inputrestore()
  return input
end

function M.setup(user_opts)
  if user_opts then
    -- Deep merge for nested tables
    for k, v in pairs(user_opts) do
      if type(v) == 'table' and type(M.config[k]) == 'table' then
        for sk, sv in pairs(v) do
          M.config[k][sk] = sv
        end
      else
        M.config[k] = v
      end
    end
  end

  vim.api.nvim_create_user_command('AiStreamSelection', function()
    M.stream_selection()
  end, {
    desc = 'Stream the current visual selection to the AI endpoint',
    range = true,
  })

  vim.api.nvim_create_user_command('AiStream', function()
    local prompt = get_user_input 'Enter your prompt: '
    if prompt and prompt ~= '' then
      M.stream_prompt(prompt)
    end
  end, {
    desc = 'Generate AI response from user input',
  })

  -- Optional: set up a visual mode mapping
  vim.keymap.set('v', '<leader>g', ':AiStreamSelection<CR>', { noremap = true, silent = true, desc = '[G]enerate AI response from selection' })
  vim.keymap.set('n', '<leader>g', ':AiStream<CR>', { noremap = true, silent = true, desc = '[G]enerate AI response from prompt' })
end

--------------------------------------------------------------------------------
-- 2. Utility: Get Visual Selection
--------------------------------------------------------------------------------
local function get_visual_selection()
  local buf = vim.api.nvim_get_current_buf()
  local start_row, start_col = unpack(vim.api.nvim_buf_get_mark(buf, '<'))
  local end_row, end_col = unpack(vim.api.nvim_buf_get_mark(buf, '>'))

  -- Handle inverted selection
  if (start_row > end_row) or (start_row == end_row and start_col > end_col) then
    start_row, end_row = end_row, start_row
    start_col, end_col = end_col, start_col
  end

  local lines = vim.api.nvim_buf_get_lines(buf, start_row - 1, end_row, false)
  if #lines == 0 then
    return ''
  end

  if #lines == 1 then
    lines[1] = string.sub(lines[1], start_col, end_col)
  else
    lines[1] = string.sub(lines[1], start_col)
    lines[#lines] = string.sub(lines[#lines], 1, end_col)
  end

  return table.concat(lines, '\n')
end

--------------------------------------------------------------------------------
-- 3. Main: Stream Prompt
--------------------------------------------------------------------------------
function M.stream_selection()
  local selection_text = get_visual_selection()
  if selection_text == '' then
    vim.notify('[ai] No text selected.', vim.log.levels.WARN)
    return
  end
  M.stream_prompt(selection_text)
end

function M.stream_prompt(prompt_text)
  if prompt_text == '' then
    vim.notify('[ai] No prompt provided.', vim.log.levels.WARN)
    return
  end

  local buf = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()
  local current_line = ''
  local line_count = vim.api.nvim_buf_line_count(buf)
  local start_line = line_count

  local payload
  if M.config.provider == 'openai' then
    payload = {
      model = M.config.openai.model,
      messages = {
        { role = 'system', content = M.config.prompt },
        { role = 'user', content = prompt_text },
      },
      stream = true,
      max_tokens = M.config.max_tokens,
      temperature = M.config.temperature,
    }
  else
    payload = {
      model = M.config.custom.model,
      prompt = prompt_text,
      stream = true,
      max_tokens = M.config.max_tokens,
      temperature = M.config.temperature,
    }
  end

  local ok, request_body = pcall(vim.fn.json_encode, payload)
  if not ok then
    vim.notify('[ai] Could not encode JSON payload.', vim.log.levels.ERROR)
    return
  end

  local endpoint = (M.config.provider == 'openai') and M.config.openai.endpoint or M.config.custom.endpoint
  local token = (M.config.provider == 'openai') and M.config.openai.token or M.config.custom.token

  local job = Job:new {
    command = 'curl',
    args = {
      '--location',
      '--no-buffer',
      '--silent',
      endpoint,
      '--header',
      'Content-Type: application/json',
      '--header',
      'Authorization: Bearer ' .. token,
      '--data',
      request_body,
    },

    on_stdout = function(_, line)
      -- Clean up SSE format and skip empty/done messages
      local clean_line = line:gsub('^data:%s*', '')
      if clean_line == '' or clean_line == '[DONE]' then
        return
      end

      -- Try to decode the JSON
      local ok, chunk = pcall(vim.json.decode, clean_line)
      if not ok then
        vim.schedule(function()
          vim.notify('[ai] Failed to decode JSON: ' .. clean_line, vim.log.levels.DEBUG)
        end)
        return
      end

      -- Extract content based on API format
      local content
      if chunk.choices and chunk.choices[1] then
        if chunk.choices[1].delta then
          content = chunk.choices[1].delta.content
        else
          content = chunk.choices[1].text
        end
      end

      if content then
        vim.schedule(function()
          -- Split content by newlines
          local lines = vim.split(current_line .. content, '\n', { plain = true })

          -- Update all lines except the last one
          if #lines > 1 then
            -- Replace current line with first line from new content
            vim.api.nvim_buf_set_lines(buf, start_line - 1, start_line, false, { lines[1] })

            -- Add all middle lines
            if #lines > 2 then
              vim.api.nvim_buf_set_lines(buf, start_line, start_line, false, vim.list_slice(lines, 2, #lines - 1))
              start_line = start_line + #lines - 2
            end

            -- Keep the last line as current_line for future updates
            current_line = lines[#lines]
            start_line = start_line + 1

            -- Add the last line
            vim.api.nvim_buf_set_lines(buf, start_line - 1, start_line, false, { current_line })
          else
            -- Single line update
            current_line = lines[1]
            vim.api.nvim_buf_set_lines(buf, start_line - 1, start_line, false, { current_line })
          end

          -- Move cursor to end of content
          vim.api.nvim_win_set_cursor(win, { start_line, #current_line })
        end)
      end
    end,

    on_stderr = function(_, err_line)
      if err_line and err_line ~= '' then
        vim.schedule(function()
          vim.notify('[ai] Error: ' .. err_line, vim.log.levels.ERROR)
        end)
      end
    end,

    on_exit = function(_, code)
      vim.schedule(function()
        if code == 0 then
          vim.notify('[ai] Stream completed!', vim.log.levels.INFO)
        else
          vim.notify('[ai] Stream failed with exit code: ' .. code, vim.log.levels.ERROR)
        end
      end)
    end,
  }

  job:start()
end

return M
