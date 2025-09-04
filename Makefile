.PHONY: install install-dev install-all test clean setup help

# Default target
help:
	@echo "Available targets:"
	@echo "  setup       - Run the setup script"
	@echo "  install     - Install core dependencies with uv"
	@echo "  install-dev - Install with development dependencies"
	@echo "  install-all - Install all optional dependencies"
	@echo "  test        - Run tests (when implemented)"
	@echo "  clean       - Clean up temporary files"
	@echo "  help        - Show this help message"

setup:
	@python3 setup.py

install:
	@echo "Installing core dependencies..."
	@uv sync

install-dev:
	@echo "Installing with development dependencies..."
	@uv sync --extra dev

install-all:
	@echo "Installing all dependencies..."
	@uv sync --extra all

test:
	@echo "Running tests..."
	@uv run pytest

clean:
	@echo "Cleaning up..."
	@find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.pyc" -delete 2>/dev/null || true
	@rm -rf .pytest_cache/ 2>/dev/null || true
	@rm -rf /tmp/nvim_jupyter_plots/ 2>/dev/null || true
	@echo "Cleanup complete"

# Quick install target for users who just want to get started
quick-install: setup install
	@echo "🎉 Quick install complete! Restart Neovim to use the plugin."