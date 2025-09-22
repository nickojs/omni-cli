#!/bin/bash

# ========================================
# Navigator Module Index
# ========================================
# Main entry point for filesystem navigation modules
# This file imports and makes available all navigator functions
# Usage: source modules/navigator/index.sh

# Get the directory where this script is located
NAVIGATOR_DIR="$(dirname "${BASH_SOURCE[0]}")"

# Import navigator modules
source "$NAVIGATOR_DIR/filesystem.sh"

# Export a function to verify navigator modules are loaded
navigator_modules_loaded() {
    echo "✓ Navigator modules loaded successfully"
    echo "  - Filesystem: $(type show_path_selector &>/dev/null && echo "✓" || echo "✗")"
}

# Function to initialize navigator modules
init_navigator() {
    # Any initialization logic for navigator modules can go here
    return 0
}