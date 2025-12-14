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
    
    
    # Handle settings command
    if [[ $choice =~ ^[Ss]$ ]]; then
        handle_settings_command
        return
    fi
    
    # Handle help command
    if [[ $choice =~ ^[Hh]$ ]]; then
        clear
        handle_help_command
        return
    fi

    # Handle kill all command
    if [[ $choice =~ ^[Kk][Aa]$ ]]; then
        handle_kill_all_command
        return
    fi

    # Handle kill commands (k1, k2, etc.)
    if [[ $choice =~ ^[Kk]([0-9]+)$ ]]; then
        local kill_choice="${BASH_REMATCH[1]}"
        handle_kill_command "$kill_choice"
        return
    fi

    # Handle custom/terminal commands (c1, c2, etc.)
    if [[ $choice =~ ^[Cc]([0-9]+)$ ]]; then
        local custom_choice="${BASH_REMATCH[1]}"
        handle_custom_command "$custom_choice"
        return
    fi

    # Handle start commands (1, 2, etc.)
    if [[ $choice =~ ^[0-9]+$ ]]; then
        handle_start_command "$choice"
        return
    fi
    
    # Invalid command
    print_error "Invalid command."
    wait_for_enter
}
