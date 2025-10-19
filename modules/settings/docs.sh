#!/bin/bash

# ========================================
# Settings Documentation & Help Module
# ========================================
# This module contains help text and documentation for the settings menu
# Usage: source modules/settings/docs.sh

# Function to show settings help
show_settings_help() {
    clear
    print_header "Settings Help"
    echo ""
    print_color "$WHITE" "This menu displays and manages your workspace configuration."
    echo ""

    echo -e "${BRIGHT_BLUE}Commands${NC}"
    echo -e "  ${WHITE}a${NC}        add workspace - create a new workspace"
    echo -e "  ${WHITE}b${NC}        back to main menu"
    echo -e "  ${WHITE}h${NC}        show this help"
    echo ""

    echo -e "${BRIGHT_BLUE}Workspaces${NC}"
    echo "  • Workspaces organize your projects by location/category"
    echo "  • Each workspace has a name and projects folder"
    echo "  • Projects are automatically scanned from the workspace folder"
    echo ""

    echo -e "${BRIGHT_BLUE}Add Workspace${NC}"
    echo "  • Opens file navigator to select a projects directory"
    echo "  • Enter a name for the workspace (or use default)"
    echo "  • Workspace will be saved and activated automatically"
    echo ""

    echo -ne "${DIM}Press Enter to continue...${NC}"
    read -r
}
