#!/bin/bash

# ========================================
# Styles Index Module
# ========================================
# Main entry point for all styling modules
# This file imports and makes available all styling functions and variables
# Usage: source libs/omni-ui-kit/index.sh

# Get the directory where this script is located
STYLES_DIR="$(dirname "${BASH_SOURCE[0]}")"

# Import all style modules
source "$STYLES_DIR/colors.sh"
source "$STYLES_DIR/animations.sh"
source "$STYLES_DIR/ui.sh"
source "$STYLES_DIR/menu.sh"

# Export a function to verify styles are loaded
styles_loaded() {
    echo "✓ Styles modules loaded successfully"
    echo "  - Colors: $([[ -n "$BRIGHT_GREEN" ]] && echo "✓" || echo "✗")"
    echo "  - Animations: $(type show_loading &>/dev/null && echo "✓" || echo "✗")"
    echo "  - UI Components: $(type print_header &>/dev/null && echo "✓" || echo "✗")"
    echo "  - Menu Helpers: $(type menu_cmd &>/dev/null && echo "✓" || echo "✗")"
    echo "  - Input Helpers: $(type read_with_instant_back &>/dev/null && echo "✓" || echo "✗")"
}
