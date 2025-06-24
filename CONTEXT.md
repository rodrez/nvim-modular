# Neovim Configuration Context

## Commands
- Format: `<leader>f` (space+f)
- Lint: Automatic on BufEnter, BufWritePost, InsertLeave
- LSP: Managed by lspconfig plugin
- Test: No specific test commands found

## Code Style
- Indentation: 2 spaces (ts=2 sts=2 sw=2 et)
- Line length: No explicit limit
- Formatting: 
  - Lua: stylua
  - JavaScript/TypeScript: prettierd, biomejs
  - Python: ruff_format, isort, black
- Linting:
  - JavaScript/TypeScript: eslint_d, biomejs
  - Python: ruff
  - Markdown: markdownlint
- Naming: Follow Lua conventions (snake_case for variables/functions)
- Imports: Group by type, no specific ordering enforced
- Error handling: Standard Lua error handling patterns

## Structure
- Modular configuration split across multiple files
- Plugin configurations in lua/kickstart/plugins/ and lua/custom/plugins/
- Core settings in lua/options.lua and lua/keymaps.lua