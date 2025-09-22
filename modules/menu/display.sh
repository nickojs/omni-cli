#!/bin/bash

# ========================================
# Menu Display Module
# ========================================
# This module handles menu display and UI functionality
# Usage: source modules/menu/display.sh

# Function to display menu and start project (for tmux session)
show_project_menu_tmux() {
    while true; do
        clear
        
        # Clean header
        print_header "Project Manager"
        
        # Check if any projects are configured
        if [ ${#projects[@]} -eq 0 ]; then
            print_error "No projects configured."
            exit 1
        fi
        
        # Display numbered menu with project info
        for i in "${!projects[@]}"; do
            IFS=':' read -r display_name folder_name startup_cmd <<< "${projects[i]}"
            display_project_status "$i" "$display_name" "$folder_name" "$startup_cmd"
        done
        echo ""
        
        # Commands section with better formatting
        if [ ${#projects[@]} -eq 1 ]; then
            echo -e "${BRIGHT_GREEN}[1]${NC} start │ ${BRIGHT_RED}[k1]${NC} kill │ ${BRIGHT_PURPLE}[s]${NC} settings │ ${BRIGHT_PURPLE}[h]${NC} help │ ${BRIGHT_PURPLE}[q]${NC} quit"
        else
            echo -e "${BRIGHT_GREEN}[1-${#projects[@]}]${NC} start │ ${BRIGHT_RED}[k1-${#projects[@]}]${NC} kill │ ${BRIGHT_PURPLE}[s]${NC} settings │ ${BRIGHT_PURPLE}[h]${NC} help │ ${BRIGHT_PURPLE}[q]${NC} quit"
        fi

        # Get user input with clean prompt
        echo ""
        echo -ne "${BRIGHT_CYAN}>${NC} "
        read -r choice
        
        # Handle user input
        handle_menu_choice "$choice"
    done
}

