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
    echo -e "${BRIGHT_WHITE}Manage your workspaces and projects${NC}"
    echo ""

    echo -e "${BRIGHT_BLUE}Available Commands${NC}"
    echo -e "  ${BRIGHT_CYAN}a${NC} add workspace      Create a new workspace"
    echo -e "  ${BRIGHT_CYAN}m${NC} manage workspace   Add, edit, or remove projects from a workspace"
    echo -e "  ${BRIGHT_CYAN}t${NC} toggle workspace   Activate or deactivate a workspace"
    echo -e "  ${BRIGHT_CYAN}b${NC} back              Return to main menu"
    echo -e "  ${BRIGHT_CYAN}h${NC} help              Show this help screen"
    echo ""

    echo -e "${BRIGHT_BLUE}What are Workspaces?${NC}"
    echo -e "  Workspaces organize projects by location or category."
    echo -e "  Each workspace has"
    echo -e "    • A name (e.g., 'Personal', 'Work', 'Clients')"
    echo -e "    • A projects folder (where your project directories live)"
    echo -e "    • Multiple projects with custom startup/shutdown commands"
    echo ""

    echo -e "${BRIGHT_BLUE}Workflow${NC}"
    echo -e "  1. Add a workspace using ${BRIGHT_CYAN}a${NC}"
    echo -e "  2. Select the workspace to manage using ${BRIGHT_CYAN}m${NC}"
    echo -e "  3. Add projects from the workspace's folder"
    echo -e "  4. Edit or remove projects as needed"
    echo ""

    wait_for_enter
}
