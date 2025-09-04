#!/usr/bin/env python3
"""
Setup script for nvim-jupyter-inline plugin
"""

import os
import sys
import subprocess
from pathlib import Path

def main():
    """Setup the nvim-jupyter-inline plugin."""
    config_dir = Path(__file__).parent
    bridge_script = config_dir / "scripts" / "jupyter_bridge.py"
    
    print("🚀 Setting up nvim-jupyter-inline plugin...")
    
    # Make bridge script executable
    if bridge_script.exists():
        os.chmod(bridge_script, 0o755)
        print(f"✅ Made {bridge_script} executable")
    else:
        print(f"❌ Bridge script not found: {bridge_script}")
        return 1
    
    # Check if uv is available
    try:
        subprocess.run(["uv", "--version"], check=True, capture_output=True)
        print("✅ uv is available")
        
        # Install dependencies with uv
        print("📦 Installing dependencies with uv...")
        subprocess.run(["uv", "sync"], cwd=config_dir, check=True)
        print("✅ Dependencies installed successfully")
        
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("⚠️  uv not found, falling back to pip...")
        
        # Install with pip
        try:
            subprocess.run([sys.executable, "-m", "pip", "install", "jupyter_client"], check=True)
            print("✅ jupyter_client installed with pip")
        except subprocess.CalledProcessError as e:
            print(f"❌ Failed to install dependencies: {e}")
            return 1
    
    print("\n🎉 Setup complete!")
    print("\nNext steps:")
    print("1. Restart Neovim")
    print("2. Open the example file: :e ~/.config/nvim/example_notebook.py")
    print("3. Place cursor in a cell and press <leader>e to execute")
    print("\nFor more information, see: ~/.config/nvim/JUPYTER_PLUGIN_README.md")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())