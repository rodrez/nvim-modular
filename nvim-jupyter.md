### **PRD: The "Inline-Output" Interactive Neovim Environment**

### **1. Overview & Goal**

This document outlines an advanced version of the `tmux`-native workflow. The primary goal is to **display the output of a Jupyter kernel directly within the Neovim buffer**, immediately following the code cell that produced it. This will emulate the behavior of a traditional Jupyter Notebook, providing a seamless, self-contained interactive experience and eliminating the need to switch to another window to view terminal output.

### **2. Guiding Principles**

* **Integrated Feedback Loop:** Output (text, errors, and plots) should appear in the same buffer as the code, creating a tight feedback loop.
* **True "Notebook" Feel:** The editor buffer should become the single source of truth, containing both the code and its results in a logical, readable sequence.
* **DIY Spirit, Pragmatic Tools:** While avoiding a monolithic plugin, we will create a custom "bridge" script to handle the complex parts of kernel communication. The solution will be composed of small, understandable parts.

### **3. Functional Requirements**

**FR-1: Kernel Communication Bridge**
* A standalone Python script must be created to act as a lightweight client for the Jupyter kernel.
* This script will accept a kernel's connection file and a string of code to execute.
* It must connect to the kernel, execute the code, and capture all resulting output messages (stdout, stderr, return values, and rich media).
* It must format the captured output into a simple, parsable text format and print it to standard output.

**FR-2: Inline Text Output**
* A Neovim keymap must trigger a process that:
    1.  Identifies the code in the current cell.
    2.  Executes the "Kernel Communication Bridge" script with that code.
    3.  Captures the script's standard output.
    4.  Deletes any previous output associated with that cell.
    5.  Inserts the newly captured output as commented lines directly below the cell in the Neovim buffer.

**FR-3: Inline Plot Handling (Pragmatic Approach)**
* True inline image rendering in a terminal is complex and terminal-dependent. The system will take a pragmatic "inline link" approach.
* When the bridge script captures a plot, it will save it as an image file (e.g., in `/tmp/`).
* The script will return the **path** to this image file as its output.
* Neovim will insert this file path as a special, identifiable line below the cell (e.g., `# OUTPUT-PLOT: /tmp/plot_123.png`).
* A separate keymap must be created to **view the plot**. When this keymap is triggered on a plot output line, it will open the image in a floating terminal window using a tool like `viu`.

### **4. Technical Implementation Plan**

1.  **Build the Python Bridge (`jupyter_bridge.py`):**
    * Use the `jupyter_client` Python library to handle kernel connection and communication.
    * Implement logic to listen on the kernel's `iopub` channel to capture output messages.
    * For text output, format it as simple strings.
    * For image output, decode the Base64 data, save it to a temporary file, and return the file path.
    * Structure the script to be called from the command line.

2.  **Configure Neovim (Lua):**
    * Write a Lua function (`ExecuteAndRenderInline`) that serves as the main engine.
    * This function will call the `jupyter_bridge.py` script as a system process.
    * It will parse the output from the bridge script.
    * It will use Neovim API functions (`nvim_buf_get_lines`, `nvim_buf_set_lines`) to manipulate the buffer, clearing old output and inserting the new.
    * Create the keymap (`<leader>e`) to trigger this function.

3.  **Implement Plot Viewing:**
    * Write a smaller Lua function (`ViewPlot`) that extracts the file path from the current line.
    * This function will use Neovim's floating terminal API to open a popup window running `viu` with the extracted file path.
    * Create the keymap (`<leader>p`) to trigger this function on plot output lines.

### **5. User Workflow (The "Happy Path")**

1.  The user is in Neovim editing a Python script file. A Jupyter kernel is running in the background.
2.  The user places their cursor on a cell containing `print("hello")` and presses `<leader>e`.
3.  A new line appears instantly below the cell: `# hello`.
4.  The user moves to a cell that generates a plot and presses `<leader>e`.
5.  A new line appears below that cell: `# OUTPUT-PLOT: /tmp/plot_abc.png`.
6.  The user moves their cursor to the plot output line and presses `<leader>p`.
7.  A floating window appears over their editor, displaying the plot. Pressing `q` closes the plot view.
8.  The entire interactive session happens within a single Neovim buffer.
