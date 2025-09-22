#!/bin/bash

# ========================================
# Documentation & Help Module
# ========================================
# This module contains all help text and status display functions
# Usage: source docs/index.sh

# Function to show settings help
show_settings_help() {
    print_header "Help"
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
    print_color "$WHITE" "This menu allows you to manage and start your configured projects."
    echo ""
    echo -e "${BRIGHT_BLUE}Start Commands${NC}"
    echo -e "  ${WHITE}1-${#projects[@]}${NC}        Start project by number"
    echo ""
    echo -e "${BRIGHT_BLUE}Kill Commands${NC}"
    echo -e "  ${WHITE}k1-k${#projects[@]}${NC}       Kill project by number"
    echo ""
    echo -e "${BRIGHT_BLUE}Utility Commands${NC}"
    echo -e "  ${WHITE}s${NC}        Open settings menu"
    echo -e "  ${WHITE}h${NC}        Show this help"
    echo -e "  ${WHITE}q${NC}        Quit and close session"
    echo ""
    echo -e "${BRIGHT_BLUE}About${NC}"
    echo "  • Projects run in separate tmux panes"
    echo "  • Use settings menu to add/edit/delete projects"
    echo "  • Kill running projects before starting new ones"
    echo ""
    echo -ne "${DIM}Press Enter to continue...${NC}"
    read -r
}

