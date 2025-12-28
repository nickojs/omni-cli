#!/bin/bash

# ========================================
# Documentation Module
# ========================================
# Help screens for menu and settings
# Usage: source modules/docs.sh

# Function to show menu help
show_menu_help() {
    clear
    print_header "Menu Help"
    echo ""
    echo -e "${BRIGHT_WHITE}Start, stop, and manage your projects${NC}"
    echo ""

    echo -e "${BRIGHT_BLUE}Available Commands${NC}"
    echo -e "  ${BRIGHT_CYAN}1-9${NC}              Start a project by its number"
    echo -e "  ${BRIGHT_CYAN}c1-c9${NC}            Open terminal in project folder"
    echo -e "  ${BRIGHT_CYAN}r1-r9${NC}            Restart a running project"
    echo -e "  ${BRIGHT_CYAN}k1-k9${NC}            Kill (stop) a project by its number"
    echo -e "  ${BRIGHT_CYAN}ka${NC}               Kill all running projects"
    echo -e "  ${BRIGHT_CYAN}s${NC}                Open settings menu"
    echo -e "  ${BRIGHT_CYAN}h${NC}                Show this help screen"
    echo -e "  ${BRIGHT_CYAN}q${NC}                Quit the application"
    echo ""

    echo -e "${BRIGHT_BLUE}Starting Projects${NC}"
    echo -e "  Each project in your workspaces is numbered in the menu."
    echo -e "  Simply type the number and press Enter to start it."
    echo -e "  Projects run in separate tmux panes with their configured startup commands."
    echo ""

    echo -e "${BRIGHT_BLUE}Restarting Projects${NC}"
    echo -e "  Use '${BRIGHT_CYAN}r${NC}' followed by the project number (e.g., ${BRIGHT_CYAN}r1${NC}) to restart a running project."
    echo -e "  This kills the process but keeps the pane, then re-runs the startup command."
    echo ""

    echo -e "${BRIGHT_BLUE}Stopping Projects${NC}"
    echo -e "  Use '${BRIGHT_RED}k${NC}' followed by the project number (e.g., ${BRIGHT_RED}k1${NC}) to stop a specific project."
    echo -e "  Use ${BRIGHT_RED}ka${NC} to stop all running projects at once."
    echo -e "  Shutdown commands configured for each project will be executed."
    echo ""

    echo -e "${BRIGHT_BLUE}Managing Workspaces${NC}"
    echo -e "  Use ${BRIGHT_CYAN}s${NC} to access settings where you can"
    echo -e "    • Add new workspaces"
    echo -e "    • Add, edit, or remove projects"
    echo -e "    • Configure startup and shutdown commands"
    echo ""

    wait_for_enter
}

# Function to show settings help
show_settings_help() {
    clear
    print_header "Settings Help"
    echo ""
    echo -e "${BRIGHT_WHITE}Manage your workspaces and projects${NC}"
    echo ""

    echo -e "${BRIGHT_BLUE}Settings Commands${NC}"
    echo -e "  ${BRIGHT_CYAN}a${NC}                  Add a new workspace"
    echo -e "  ${BRIGHT_CYAN}m1-mx${NC}              Manage workspace by number"
    echo -e "  ${BRIGHT_CYAN}t1-tx${NC}              Toggle workspace active/inactive by number"
    echo -e "  ${BRIGHT_CYAN}b${NC}                  Return to main menu"
    echo -e "  ${BRIGHT_CYAN}h${NC}                  Show this help screen"
    echo ""

    echo -e "${BRIGHT_BLUE}Workspace Management Commands${NC}"
    echo -e "  ${BRIGHT_CYAN}a${NC}                  Add a project to the workspace"
    echo -e "  ${BRIGHT_CYAN}e1-ex${NC}              Edit project by number"
    echo -e "  ${BRIGHT_CYAN}r1-rx${NC}              Remove project by number"
    echo -e "  ${BRIGHT_CYAN}d${NC}                  Delete the workspace"
    echo -e "  ${BRIGHT_CYAN}b${NC}                  Go back to settings"
    echo ""

    echo -e "${BRIGHT_BLUE}What are Workspaces?${NC}"
    echo -e "  Workspaces organize projects by location or category."
    echo -e "  Each workspace has:"
    echo -e "    - A name (e.g., 'Personal', 'Work', 'Clients')"
    echo -e "    - A projects folder (where your project directories live)"
    echo -e "    - Multiple projects with custom startup/shutdown commands"
    echo ""

    echo -e "${BRIGHT_BLUE}Workflow${NC}"
    echo -e "  1. Add a workspace using ${BRIGHT_CYAN}a${NC}"
    echo -e "  2. Manage the workspace using ${BRIGHT_CYAN}m1${NC}, ${BRIGHT_CYAN}m2${NC}, etc."
    echo -e "  3. Add projects using ${BRIGHT_CYAN}a${NC} in the workspace screen"
    echo -e "  4. Edit or remove projects using ${BRIGHT_CYAN}e1${NC}/${BRIGHT_CYAN}r1${NC}, etc."
    echo ""

    wait_for_enter
}


