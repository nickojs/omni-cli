#!/bin/bash

# ========================================
# Documentation & Help Module
# ========================================
# This module contains all help text and status display functions
# Usage: source docs/index.sh

# Function to show settings help
show_settings_help() {
    print_header "Settings Help"
    print_color "$WHITE" "This menu displays your current project configuration."
    echo ""
    echo -e "${BRIGHT_BLUE}Commands${NC}"
    echo -e "  ${WHITE}a${NC}        add mode"
    echo -e "  ${WHITE}d${NC}        delete mode"
    echo -e "  ${WHITE}e${NC}        edit mode"
    echo -e "  ${WHITE}b${NC}        back to main menu"
    echo -e "  ${WHITE}h${NC}        show this help"
    echo ""

    echo -e "${BRIGHT_BLUE}Configuration${NC}"
    echo "  • Display Name - how the project appears in menus"
    echo "  • Folder Name - the actual directory name"
    echo ""
    echo -e "${BRIGHT_BLUE}Modes${NC}"
    echo "  • Add Mode - scan and add new projects from your projects directory"
    echo "  • Delete Mode - select projects to remove"
    echo "  • Edit Mode - select projects to modify"
    echo "  • Press Enter while in a mode to return to Settings"
    echo ""
    echo -ne "${DIM}Press Enter to continue...${NC}"
    read -r
}

# Function to show main menu help
show_help() {
    print_header "Help"
    echo -e "${BRIGHT_GREEN}Start Commands${NC}"
    echo -e "  ${BRIGHT_GREEN}1-${#projects[@]}${NC}    Start project by number"
    echo ""
    echo -e "${BRIGHT_RED}Kill Commands${NC}"
    echo -e "  ${BRIGHT_RED}k1-k${#projects[@]}${NC}  Kill project by number"
    echo ""
    echo -e "${BRIGHT_PURPLE}Utility Commands${NC}"
    echo -e "  ${BRIGHT_PURPLE}s${NC}        Open settings menu"
    echo -e "  ${BRIGHT_PURPLE}h${NC}        Show this help"
    echo -e "  ${BRIGHT_PURPLE}q${NC}        Quit and close session"
    echo ""
    echo -ne "${DIM}Press Enter to continue...${NC}"
    read -r
}

