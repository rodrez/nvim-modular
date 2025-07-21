return {
  { -- Linting
    'mfussenegger/nvim-lint',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local lint = require 'lint'

      -- Function to check if a file exists in the project root or current directory
      local function file_exists(filename)
        local cwd = vim.fn.getcwd()
        -- Check current directory and walk up the tree
        local current = cwd
        while current ~= '/' do
          local filepath = current .. '/' .. filename
          if vim.fn.filereadable(filepath) == 1 then
            return true
          end
          current = vim.fn.fnamemodify(current, ':h')
          -- Stop if reached root or parent is same as current
          if current == vim.fn.fnamemodify(current, ':h') then
            break
          end
        end
        return false
      end

      -- Function to check for files matching patterns
      local function has_files_matching(patterns)
        local cwd = vim.fn.getcwd()
        local current = cwd

        while current ~= '/' do
          for _, pattern in ipairs(patterns) do
            local matches = vim.fn.glob(current .. '/' .. pattern, false, true)
            if #matches > 0 then
              return true
            end
          end
          current = vim.fn.fnamemodify(current, ':h')
          -- Stop if reached root or parent is same as current
          if current == vim.fn.fnamemodify(current, ':h') then
            break
          end
        end
        return false
      end

      -- Function to get available JS/TS linters based on config files
      local function get_js_linters()
        local linters = {}

        -- Check for biome config files using patterns
        if has_files_matching({ 'biome.json*' }) then
          table.insert(linters, 'biomejs')
        end

        -- Check for eslint config files using patterns
        local eslint_patterns = {
          '.eslintrc*',     -- Covers .eslintrc, .eslintrc.js, .eslintrc.json, etc.
          'eslint.config.*' -- Covers eslint.config.js, eslint.config.mjs, etc.
        }

        if has_files_matching(eslint_patterns) then
          table.insert(linters, 'eslint_d')
        end

        -- Check package.json for eslintConfig field
        if file_exists('package.json') then
          local package_json = vim.fn.readfile(vim.fn.getcwd() .. '/package.json')
          local content = table.concat(package_json, '\n')
          if string.find(content, '"eslintConfig"') then
            table.insert(linters, 'eslint_d')
          end
        end

        -- Fallback: if no config found, prefer biome over eslint
        if #linters == 0 then
          linters = { 'biomejs' }
        end

        return linters
      end

      -- Get the appropriate linters for JS/TS files
      local js_linters = get_js_linters()

      lint.linters_by_ft = {
        markdown = { 'markdownlint' },
        javascript = js_linters,
        typescript = js_linters,
        javascriptreact = js_linters,
        typescriptreact = js_linters,
        python = { 'ruff' },
      }

      -- Create autocommand which carries out the actual linting
      local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
      vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
        group = lint_augroup,
        callback = function()
          require('lint').try_lint()
          require('lint').try_lint 'cspell'
        end,
      })
    end,
  },
}
