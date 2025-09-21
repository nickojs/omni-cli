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
    
    # Handle quit command
    if [[ $choice =~ ^[Qq]$ ]]; then
        handle_quit_command
        return
    fi
    
    # Handle back command
    if [[ $choice =~ ^[Bb]$ ]]; then
        return 1  # Return to previous menu
    fi
    
    # Handle help command
    if [[ $choice =~ ^[Hh]$ ]]; then
        show_settings_help
        return
    fi
    
    # Invalid command
    print_error "Invalid command. Use m (mode), b (back), h (help), or q (quit)"
    sleep 2
}

# Function to handle list config command
handle_list_config_command() {
    clear
    list_current_config
    echo ""
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

# Function to handle reset config command (placeholder)
handle_reset_config_command() {
    clear
    print_header "RESET CONFIGURATION"
    echo ""
    print_color "$BRIGHT_YELLOW" "This feature is coming soon!"
    echo "You'll be able to:"
    echo "• Reset configuration to defaults"
    echo "• Clear all project configurations"
    echo "• Re-run the setup wizard"
    echo ""
    echo -ne "${BRIGHT_YELLOW}Press Enter to continue...${NC}"
    read -r
}
