#!/bin/bash

# ========================================
# Modules Index
# ========================================
# Main entry point for all business logic modules
# This file imports and makes available all module functions
# Usage: source modules/index.sh

# Get the directory where this script is located
MODULES_DIR="$(dirname "${BASH_SOURCE[0]}")"

# Import all modules in dependency order
source "$MODULES_DIR/config/index.sh"     # Configuration and JSON parsing
source "$MODULES_DIR/tmux.sh"       # Tmux session management
source "$MODULES_DIR/project.sh"    # Project status and management
source "$MODULES_DIR/menu/index.sh"       # Interactive menu system
source "$MODULES_DIR/wizard.sh"       # Wizard installation and setup

# Export a function to verify modules are loaded
modules_loaded() {
    echo "✓ Business logic modules loaded successfully"
    echo "  - Config: $(type load_config &>/dev/null && echo "✓" || echo "✗")"
    echo "  - Tmux: $(type check_tmux &>/dev/null && echo "✓" || echo "✗")"
    echo "  - Project: $(type display_project_status &>/dev/null && echo "✓" || echo "✗")"
    echo "  - Menu: $(type show_project_menu_tmux &>/dev/null && echo "✓" || echo "✗")"
    echo "  - Wizard: $(type run_wizard &>/dev/null && echo "✓" || echo "✗")"
    
    # Also check config sub-modules
    if type config_modules_loaded &>/dev/null; then
        echo ""
        config_modules_loaded
    fi
    
    # Also check menu sub-modules
    if type menu_modules_loaded &>/dev/null; then
        echo ""
        menu_modules_loaded
    fi
}

# Function to initialize all modules
init_modules() {
    # Any initialization logic for modules can go here
    return 0
}
