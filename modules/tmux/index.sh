#!/bin/bash

# ========================================
# Tmux Module Index
# ========================================
# Main entry point for all tmux modules
# This file imports and makes available all tmux functions
# Usage: source modules/tmux/index.sh

# Get the directory where this script is located
TMUX_DIR="$(dirname "${BASH_SOURCE[0]}")"

# Import all tmux modules in dependency order
source "$TMUX_DIR/session.sh"      # Session management
source "$TMUX_DIR/pane.sh"         # Pane management
source "$TMUX_DIR/project.sh"      # Project-specific operations

# Export a function to verify tmux modules are loaded
tmux_modules_loaded() {
    echo "✓ Tmux modules loaded successfully"
    echo "  - Session: $(type setup_tmux_session &>/dev/null && echo "✓" || echo "✗")"
    echo "  - Pane: $(type get_project_pane &>/dev/null && echo "✓" || echo "✗")"
    echo "  - Project: $(type start_project_in_tmux &>/dev/null && echo "✓" || echo "✗")"
}
