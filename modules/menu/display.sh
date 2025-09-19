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
        
        # Fancy header
        print_header "PROJECT STARTUP MENU"
        
        # Check if any projects are configured
        if [ ${#projects[@]} -eq 0 ]; then
            print_error "No projects configured."
            exit 1
        fi
        
        # Display numbered menu with project info
        echo ""
        for i in "${!projects[@]}"; do
            IFS=':' read -r display_name folder_name startup_cmd <<< "${projects[i]}"
            display_project_status "$i" "$display_name" "$folder_name" "$startup_cmd"
        done
        echo ""
        
        print_separator
        
        # Commands section with better formatting
        print_divider "COMMANDS"
        if [ ${#projects[@]} -eq 1 ]; then
            echo -e "${BRIGHT_GREEN}[1]${NC} start │ ${BRIGHT_RED}[k1]${NC} kill │ ${BRIGHT_YELLOW}[r]${NC} refresh │ ${BRIGHT_PURPLE}[w]${NC} wizard │ ${BRIGHT_PURPLE}[q]${NC} quit"
        else
            echo -e "${BRIGHT_GREEN}[1-${#projects[@]}]${NC} start │ ${BRIGHT_RED}[k1-k${#projects[@]}]${NC} kill │ ${BRIGHT_YELLOW}[r]${NC} refresh │ ${BRIGHT_PURPLE}[w]${NC} wizard │ ${BRIGHT_PURPLE}[q]${NC} quit"
        fi
        
        print_separator
        
        # Get user input with prompt (removed emoji)
        echo ""
        echo -ne "${BRIGHT_WHITE}Enter command${NC} ${BRIGHT_CYAN}>>${NC} "
        read -r choice
        
        # Handle user input
        handle_menu_choice "$choice"
    done
}

# Function to show help menu
show_help() {
    print_header "HELP - AVAILABLE COMMANDS"
    echo ""
    echo -e "${BRIGHT_GREEN}Start Commands:${NC}"
    echo -e "  ${BRIGHT_CYAN}1-${#projects[@]}${NC}    Start project by number"
    echo ""
    echo -e "${BRIGHT_RED}Kill Commands:${NC}"
    echo -e "  ${BRIGHT_CYAN}k1-k${#projects[@]}${NC}  Kill project by number"
    echo ""
    echo -e "${BRIGHT_YELLOW}Utility Commands:${NC}"
    echo -e "  ${BRIGHT_CYAN}r${NC}        Refresh project status"
    echo -e "  ${BRIGHT_CYAN}w${NC}        Re-run setup wizard"
    echo -e "  ${BRIGHT_CYAN}h${NC}        Show this help"
    echo -e "  ${BRIGHT_CYAN}q${NC}        Quit and close session"
    echo ""
    echo -ne "${BRIGHT_YELLOW}Press Enter to continue...${NC}"
    read -r
}
