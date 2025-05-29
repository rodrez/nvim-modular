# Tmuxscope - Telescope Tmux Session Manager

A Telescope extension for Neovim that provides seamless tmux session management directly from your editor.

## Project Structure

```
~/.config/nvim/
├── lua/
│   ├── kickstart/
│   │   └── plugins/
│   │       └── telescope.lua              # Modified to include tmuxscope config
│   └── telescope/
│       └── _extensions/
│           └── tmuxscope.lua              # Main extension implementation
└── TMUX_TELESCOPE_EXTENSION.md           # This documentation
```

## Features

### Session Management
- **Command**: `:Telescope tmuxscope sessions`
- **Keymap**: `<leader>ts`
- **Description**: Lists all active tmux sessions with detailed information
- **Display Format**: `1. session_name (3 windows) [attached]`
- **Actions**:
  - `<Enter>`: Switch to selected session
  - `<C-x>`: Delete selected session

**Smart Session Switching:**
- Inside tmux: Uses `tmux switch -t session_name`
- Outside tmux: Provides attach command and copies to clipboard

### New Session Creation
- **Command**: `:Telescope tmuxscope new_session`
- **Keymap**: `<leader>tn`
- **Description**: Creates new tmux sessions from configured directory paths
- **Behavior**: 
  - Searches through configured paths for directories
  - Creates session with directory name
  - Automatically switches to new session

## Configuration

The extension is configured in `lua/kickstart/plugins/telescope.lua`:

```lua
tmuxscope = {
  search_paths = {
    '~/projects',
    '~/work', 
    '~/dev',
    '~/.config',
    '~/Documents',
  },
},
```

## Implementation Details

### Core Functions
- `get_tmux_sessions()`: Retrieves session info using tmux list-sessions
- `switch_to_session()`: Handles session switching with tmux detection
- `create_session()`: Creates new sessions in specified directories
- `delete_session()`: Safely removes tmux sessions
- `get_directories()`: Scans configured paths for available directories

### Key Features
- **Tmux Detection**: Automatically detects if running inside tmux
- **Error Handling**: Graceful handling of tmux command failures
- **Directory Filtering**: Excludes hidden directories from search results
- **Session Validation**: Checks for existing sessions before creation

## Usage Examples

### Quick Session Switch
1. Press `<leader>ts`
2. Select session from list
3. Press `<Enter>` to switch

### Create Project Session
1. Press `<leader>tn`
2. Navigate to desired project directory
3. Press `<Enter>` to create and switch to session

### Delete Unused Sessions
1. Press `<leader>ts`
2. Navigate to session to delete
3. Press `<C-x>` to delete session

## Dependencies

- **tmux**: Must be installed and available in PATH
- **telescope.nvim**: Core telescope functionality
- **plenary.nvim**: Lua utility functions (telescope dependency)

## Installation Notes

The extension is automatically loaded through the telescope configuration. No additional installation steps required beyond ensuring the files are in the correct locations. 