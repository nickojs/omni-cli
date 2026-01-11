#!/bin/bash

# ========================================
# Documentation Module
# ========================================
# Help screens for menu and settings
# Usage: source modules/docs.sh

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

display_secrets_help() {
    clear
    print_header "Secrets Help"
    echo ""
    echo -e "${DIM}This tool uses ${NC}${BOLD}user-generated ${NC}${BRIGHT_CYAN}age${NC}${DIM} keypairs to manage ${NC}${BRIGHT_CYAN}gocryptfs${NC}${DIM} volumes (aka vaults).${NC}"
    echo ""
    echo -e "${DIM}To add a secret, provide an encrypted passphrase (${NC}${ITALIC}.age${NC}${DIM}) and its corresponding ${NC}${ITALIC}keypairs${NC}${DIM}.${NC}"
    echo -e "${DIM}Secrets are then used to create, mount and unmount ${NC}${ITALIC}vaults${NC}${DIM}. Existing vaults that relies on .age can also be managed.${NC}"
    echo ""
    echo -e "${DIM}How it works:${NC}"
    echo -e "  ${BRIGHT_WHITE}create passphrase${NC} ${DIM}→${NC} ${BRIGHT_WHITE}encrypt with age${NC} ${DIM}→${NC} ${BRIGHT_CYAN}.age file and keypair${NC} ${DIM}→${NC} ${BRIGHT_WHITE}add it here (a secret!)${NC} ${DIM}→${NC} ${BRIGHT_CYAN}manage vault(s)${NC}"
    echo ""
    echo -e "${BOLD}Files and folders are not touched:${NC}${DIM} This tool only ${ITALIC}manages${NC} the secrets and vaults. Deletion of those files should be user's responsibility.${NC}"
    echo ""
    echo -e "${BOLD}Optional auto-detect encrypted passphrases:${NC}${DIM} use your keypair name as prefix of your .age file(s), separated by underscore.${NC}"
    echo -e "${DIM}This will only work if your public and private key shares the same file name.${NC}"
    echo ""    
    echo -e "  ${BRIGHT_CYAN}mykey${NC}${DIM} - public/private key file name${NC}"
    echo -e "  ${BRIGHT_CYAN}mykey${NC}${DIM}_${NC}${BOLD}anyfilename.age${NC}${DIM} - automatically detected, assigned to that keypair${NC}"
    echo ""
    echo -e "${BRIGHT_CYAN}age${NC} — simple, modern file encryption tool (${BRIGHT_CYAN}https://github.com/FiloSottile/age${NC})"
    echo -e "${BRIGHT_CYAN}gocryptfs${NC} — encrypted overlay filesystem (${BRIGHT_CYAN}https://github.com/rfjakob/gocryptfs${NC})"
    echo ""
    echo -e "Check *this* project's documentation to understand this approach in deep. (${BRIGHT_CYAN}https://placeholder${NC})" # Placeholder URL, project's doc will be *this* project's doc
    echo ""

    wait_for_enter
}

# Display help content
display_navigator_help() {
    clear
    print_header "Navigator Help"
    echo ""
    echo -e "${DIM}Interactive filesystem browser for selecting directories or files.${NC}"
    echo ""
    echo -e "${BOLD}Navigation${NC}"
    echo -e "  ${BRIGHT_YELLOW}w${NC} ${DIM}/${NC} ${BRIGHT_YELLOW}s${NC}      ${DIM}move selection up/down within current page${NC}"
    echo -e "  ${BRIGHT_CYAN}[${NC} ${DIM}/${NC} ${BRIGHT_CYAN}]${NC}      ${DIM}go to previous/next page${NC}"
    echo -e "  ${BRIGHT_CYAN}1-99${NC}     ${DIM}type a number and press enter to jump directly${NC}"
    echo -e "  ${BRIGHT_GREEN}enter${NC}    ${DIM}open selected directory${NC}"
    echo ""
    echo -e "${BOLD}Selection${NC}"
    echo -e "  ${BRIGHT_BLUE}space${NC}    ${DIM}confirm selection (directory mode: select current folder)${NC}"
    echo -e "  ${BRIGHT_RED}b${NC}        ${DIM}go back / cancel${NC}"
    echo ""
    echo -e "${BOLD}File Mode Only${NC}"
    echo -e "  ${BRIGHT_PURPLE}m${NC}        ${DIM}mark/unmark current file${NC}"
    echo -e "  ${BRIGHT_CYAN}l${NC}        ${DIM}list all marked files${NC}"
    echo -e "  ${BRIGHT_BLUE}space${NC}    ${DIM}confirm marked files selection${NC}"
    echo ""
    echo -e "${DIM}Selection wraps within each page. Marked files persist across pages.${NC}"
    echo ""

    wait_for_enter
}