# From Menu module

# Function to show menu help
show_menu_help() {
    clear
    print_header "Menu Help"
    echo ""
    echo -e "${BRIGHT_WHITE}Start, stop, and manage your projects${NC}"
    echo ""

    echo -e "${BRIGHT_BLUE}Available Commands${NC}"
    echo -e "  ${BRIGHT_CYAN}1-9${NC}              Start a project by its number"
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


