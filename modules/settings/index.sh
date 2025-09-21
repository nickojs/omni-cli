#!/bin/bash

# ========================================
# Settings Module Index
# ========================================
# Main entry point for all settings modules
# This file imports and makes available all settings functions
# Usage: source modules/settings/index.sh

# Get the directory where this script is located
SETTINGS_DIR="$(dirname "${BASH_SOURCE[0]}")"

# Import all settings modules
source "$SETTINGS_DIR/display.sh"         # Settings menu display
source "$SETTINGS_DIR/commands.sh"        # Settings command handling
source "$SETTINGS_DIR/config-display.sh"  # Configuration display functions

# Export a function to verify settings modules are loaded
settings_modules_loaded() {
    echo "✓ Settings modules loaded successfully"
    echo "  - Display: $(type show_settings_menu &>/dev/null && echo "✓" || echo "✗")"
    echo "  - Commands: $(type handle_settings_choice &>/dev/null && echo "✓" || echo "✗")"
    echo "  - Config Display: $(type list_current_config &>/dev/null && echo "✓" || echo "✗")"
}

# Function to initialize settings modules
init_settings() {
    # Any initialization logic for settings modules can go here
    return 0
}
