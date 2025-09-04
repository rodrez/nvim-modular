# Neovim Jupyter Inline Plugin

A custom Neovim plugin that provides Jupyter notebook-like functionality with inline output display, following the PRD specifications for an "Inline-Output" Interactive Neovim Environment.

## Features

- **Inline Output Display**: Execute Python code cells and see results directly in your Neovim buffer
- **Plot Support**: Generate and view plots with a simple keymap
- **Cell-based Execution**: Organize code in cells using `# %%` markers
- **Error Handling**: Display execution errors inline with clear formatting
- **Visual Selection**: Execute selected code blocks
- **Kernel Management**: Connect to existing Jupyter kernels or start new ones

## Installation

### Prerequisites

#### Option 1: Using uv (Recommended)

1. **Install uv** (if not already installed):
   ```bash
   curl -LsSf https://astral.sh/uv/install.sh | sh
   # or
   pip install uv
   ```

2. **Install dependencies**:
   ```bash
   cd ~/.config/nvim
   uv sync                    # Install core dependencies
   uv sync --extra plotting   # Include matplotlib/numpy for plotting
   uv sync --extra all        # Install everything including dev tools
   ```

#### Option 2: Using pip

1. **Python Dependencies**:
   ```bash
   pip install jupyter_client
   ```

2. **Optional Dependencies**:
   ```bash
   # For plotting support
   pip install matplotlib numpy
   
   # For image viewing
   pip install viu          # Terminal image viewer (recommended)
   brew install feh         # macOS/Linux image viewer
   # or use built-in 'open' command on macOS
   ```

### Plugin Setup

#### Quick Setup (Recommended)

```bash
cd ~/.config/nvim
make quick-install
# or
python3 setup.py
```

#### Manual Setup

The plugin files are located at:

- **Main Plugin**: `~/.config/nvim/lua/custom/plugins/jupyter-inline.lua`
- **Python Bridge**: `~/.config/nvim/scripts/jupyter_bridge.py`
- **Example File**: `~/.config/nvim/example_notebook.py`
- **Dependencies**: `~/.config/nvim/pyproject.toml`

#### Available Make Targets

```bash
make help          # Show available commands
make setup         # Run setup script
make install       # Install core dependencies
make install-all   # Install all dependencies
make clean         # Clean temporary files
```

## Usage

### Basic Workflow

1. **Create a Python file** with cell markers:
   ```python
   # %% Cell 1
   print("Hello World")
   
   # %% Cell 2  
   x = 42
   print(f"Answer: {x}")
   ```

2. **Execute cells**:
   - Place cursor in a cell and press `<leader>e`
   - Or select code and press `<leader>e` in visual mode

3. **View output**: Results appear as commented lines below the cell:
   ```python
   # %% Cell 1
   print("Hello World")
   # Hello World
   ```

### Keymaps

| Keymap | Mode | Action |
|--------|------|--------|
| `<leader>e` | Normal | Execute current cell |
| `<leader>e` | Visual | Execute selected code |
| `<leader>p` | Normal | View plot on current line |
| `<leader>c` | Normal | Clear current cell output |

### Commands

| Command | Description |
|---------|-------------|
| `:JupyterExecuteCell` | Execute current cell |
| `:JupyterViewPlot` | View plot on current line |
| `:JupyterClearOutput` | Clear current cell output |
| `:JupyterSetConnection <file>` | Set Jupyter kernel connection file |

### Working with Plots

When code generates a plot, you'll see a line like:
```python
# OUTPUT-PLOT: /tmp/nvim_jupyter_plots/plot_1234567890.png
```

Place your cursor on this line and press `<leader>p` to view the plot in a floating window.

### Cell Structure

Cells are defined using `# %%` markers:

```python
# %% This is cell 1
print("First cell")

# %% This is cell 2  
x = 10
y = 20
print(f"Sum: {x + y}")

# %% Plot example
import matplotlib.pyplot as plt
plt.plot([1, 2, 3, 4])
plt.show()
```

### Connecting to Existing Kernels

If you have a running Jupyter kernel, you can connect to it:

1. Find the connection file (usually in `~/.local/share/jupyter/runtime/`)
2. Set it in Neovim:
   ```vim
   :JupyterSetConnection ~/.local/share/jupyter/runtime/kernel-12345.json
   ```

## Configuration

You can customize the plugin by modifying the setup in `jupyter-inline.lua`:

```lua
require('custom.plugins.jupyter-inline').setup({
  timeout = 60,  -- Execution timeout in seconds
  keymaps = {
    execute = '<leader>je',      -- Custom execute keymap
    view_plot = '<leader>jp',    -- Custom plot viewing keymap
    clear_output = '<leader>jc', -- Custom clear output keymap
  },
  cell_markers = {
    start = '# %%',  -- Cell start marker
    end = '# %%',    -- Cell end marker  
  }
})
```

## Troubleshooting

### Common Issues

1. **"jupyter_client not installed"**:
   ```bash
   pip install jupyter_client
   ```

2. **"Bridge script not found"**:
   - Ensure the script exists at `~/.config/nvim/scripts/jupyter_bridge.py`
   - Check that it's executable: `chmod +x ~/.config/nvim/scripts/jupyter_bridge.py`

3. **"No image viewer found"**:
   ```bash
   pip install viu  # or install feh/other image viewer
   ```

4. **Execution timeout**:
   - Increase timeout in configuration
   - Check if kernel is responsive

### Debug Mode

To debug execution issues, you can run the bridge script manually:

```bash
cd ~/.config/nvim
python3 scripts/jupyter_bridge.py "print('test')"
```

## Example Session

Try opening the example file:
```vim
:e ~/.config/nvim/example_notebook.py
```

Then:
1. Place cursor in the first cell
2. Press `<leader>e` to execute
3. See the output appear below the cell
4. Try the other cells to see different types of output

## Architecture

The plugin consists of two main components:

1. **Python Bridge** (`jupyter_bridge.py`): Handles Jupyter kernel communication
2. **Lua Plugin** (`jupyter-inline.lua`): Provides Neovim integration and UI

This architecture follows the PRD's "DIY Spirit" principle, keeping components small and understandable while providing powerful functionality.