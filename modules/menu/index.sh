#!/bin/bash

# ========================================
# Menu Module Index
# ========================================
# Main entry point for all menu modules
# This file imports and makes available all menu functions
# Usage: source modules/menu/index.sh

# Get the directory where this script is located
MENU_DIR="$(dirname "${BASH_SOURCE[0]}")"

# Import all menu modules in dependency order
source "$MENU_DIR/docs.sh"            # Documentation and help functions
source "$MENU_DIR/actions.sh"         # Action handlers (start, kill, quit, etc.)
source "$MENU_DIR/commands.sh"        # Command handling functions
source "$MENU_DIR/display.sh"         # Menu display and UI functions

# Export a function to verify menu modules are loaded
menu_modules_loaded() {
    echo "✓ Menu modules loaded successfully"
    echo "  - Display: $(type show_project_menu_tmux &>/dev/null && echo "✓" || echo "✗")"
    echo "  - Commands: $(type handle_menu_choice &>/dev/null && echo "✓" || echo "✗")"
    echo "  - Actions: $(type handle_start_command &>/dev/null && echo "✓" || echo "✗")"
}

# Function to initialize menu modules
init_menu() {
    # Any initialization logic for menu modules can go here
    return 0
}
