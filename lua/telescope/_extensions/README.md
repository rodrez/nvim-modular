# Tmuxscope - Telescope Tmux Session Manager

A Telescope extension for managing tmux sessions directly from Neovim.

## Features

- List and switch between existing tmux sessions
- Create new tmux sessions from predefined directories
- Delete tmux sessions
- Works both inside and outside tmux

## Usage

### List and Switch Sessions

```vim
:Telescope tmuxscope sessions
```

This will show all existing tmux sessions with:
- Session name
- Number of windows
- Attachment status

**Keybindings:**
- `<Enter>`: Switch to selected session
- `<C-x>`: Delete selected session

### Create New Session

```vim
:Telescope tmuxscope new_session
```

This will show directories from your configured search paths where you can create new tmux sessions.

## Configuration

Add to your telescope setup:

```lua
require('telescope').setup {
  extensions = {
    tmuxscope = {
      search_paths = {
        '~/projects',
        '~/work',
        '~/dev',
        '~/.config',
        '~/Documents',
      },
      tmux_command = 'tmux', -- Optional: specify tmux command path
    },
  },
}

-- Load the extension
require('telescope').load_extension('tmuxscope')
```

## Keymaps

You can set up convenient keymaps:

```lua
vim.keymap.set('n', '<leader>ts', function()
  require('telescope').extensions.tmuxscope.sessions()
end, { desc = '[T]mux [S]essions' })

vim.keymap.set('n', '<leader>tn', function()
  require('telescope').extensions.tmuxscope.new_session()
end, { desc = '[T]mux [N]ew session' })
``` 