#!/bin/bash

# ========================================
# Settings Commands Module
# ========================================
# This module handles settings menu command routing and processing
# Usage: source modules/settings/commands.sh

# Function to handle settings menu choices
handle_settings_choice() {
    local choice="$1"

    # Handle back command
    if [[ $choice =~ ^[Bb]$ ]]; then
        return 1  # Return to previous menu
    fi

    # Handle help command
    if [[ $choice =~ ^[Hh]$ ]]; then
        show_settings_help
        return 0
    fi

    # Handle add workspace command
    if [[ $choice =~ ^[Aa]$ ]]; then
        show_add_workspace_screen
        return 0
    fi

    # Handle manage workspace command
    if [[ $choice =~ ^[Mm]$ ]]; then
        show_workspace_selection_menu
        return 0
    fi

    # Handle toggle workspace command
    if [[ $choice =~ ^[Tt]$ ]]; then
        show_toggle_workspace_menu
        return 0
    fi

    # Invalid command
    print_error "Invalid command. Use a (add workspace), m (manage workspace), t (toggle workspace), b (back) or h (help)"
    wait_for_enter
    return 0
}
