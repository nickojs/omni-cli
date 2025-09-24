#!/bin/bash

# ========================================
# Settings Commands Module
# ========================================
# This module handles settings menu command routing and processing
# Usage: source modules/settings/commands.sh

# Function to handle settings menu choices
handle_settings_choice() {
    local choice="$1"
    local current_mode="$2"
    
    
    # Handle back command
    if [[ $choice =~ ^[Bb]$ ]]; then
        return 1  # Return to previous menu
    fi
    
    # Handle help command
    if [[ $choice =~ ^[Hh]$ ]]; then
        show_settings_help
        return
    fi

    # Handle add command
    if [[ $choice =~ ^[Aa]$ ]]; then
        show_add_project_screen
        return
    fi

    # Handle projects management command
    if [[ $choice =~ ^[Pp]$ ]]; then
        show_projects_management_screen
        return
    fi

    # Invalid command
    print_error "Invalid command. Use a (add), p (projects), b (back) or h (help)"
    echo -ne "${BRIGHT_YELLOW}Press Enter to continue...${NC}"
    read -r
}

# Function to handle edit config command (placeholder)
handle_edit_config_command() {
    clear
    print_header "EDIT CONFIGURATION"
    echo ""
    print_color "$BRIGHT_YELLOW" "This feature is coming soon!"
    echo "You'll be able to:"
    echo "• Add new projects to configuration"
    echo "• Edit existing project settings"
    echo "• Remove projects from configuration"
    echo "• Change project display names and startup commands"
    echo ""
    echo -ne "${BRIGHT_YELLOW}Press Enter to continue...${NC}"
    read -r
}