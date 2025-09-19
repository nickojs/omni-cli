#!/bin/bash

# ========================================
# Menu Commands Module
# ========================================
# This module handles menu command routing and processing
# Usage: source modules/menu/commands.sh

# Function to handle menu choices
handle_menu_choice() {
    local choice="$1"
    
    # Handle quit command
    if [[ $choice =~ ^[Qq]$ ]]; then
        handle_quit_command
        return
    fi
    
    # Handle refresh command
    if [[ $choice =~ ^[Rr]$ ]]; then
        handle_refresh_command
        return
    fi
    
    # Handle wizard command
    if [[ $choice =~ ^[Ww]$ ]]; then
        handle_wizard_command
        return
    fi
    
    # Handle kill commands (k1, k2, etc.)
    if [[ $choice =~ ^[Kk]([0-9]+)$ ]]; then
        local kill_choice="${BASH_REMATCH[1]}"
        handle_kill_command "$kill_choice"
        return
    fi
    
    # Handle start commands (1, 2, etc.)
    if [[ $choice =~ ^[0-9]+$ ]]; then
        handle_start_command "$choice"
        return
    fi
    
    # Invalid command
    print_error "Invalid command. Use numbers 1-${#projects[@]}, k1-k${#projects[@]}, r, w, or q"
    sleep 2
}
