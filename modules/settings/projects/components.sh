#!/bin/bash

# ========================================
# Projects UI Components Module
# ========================================
# This module handles UI display components for project operations
# Usage: source modules/settings/projects/components.sh

# Function to show project configuration input screen
# Parameters: selected_folder
show_project_configuration_screen() {
    local selected_folder="$1"
    local projects_root="$2"

    clear
    print_header "Configure Project"
    echo ""
    echo -e "${BRIGHT_CYAN}Adding project:${NC} ${BRIGHT_WHITE}${selected_folder}${NC}"
    echo -e "${DIM}Location: ${projects_root%/}/${selected_folder}${NC}"
    echo ""
}

# Function to show project configuration summary
# Parameters: display_name, selected_folder, startup_cmd, shutdown_cmd
show_project_confirmation_screen() {
    local display_name="$1"
    local selected_folder="$2"
    local startup_cmd="$3"
    local shutdown_cmd="$4"

    clear
    print_header "Confirm Project Configuration"
    echo ""
    echo -e "  ${DIM}Display Name${NC}"
    echo -e "  ${BRIGHT_WHITE}${display_name}${NC}"
    echo ""
    echo -e "  ${DIM}Folder${NC}"
    echo -e "  ${BRIGHT_WHITE}${selected_folder}${NC}"
    echo ""
    echo -e "  ${DIM}Startup Command${NC}"
    echo -e "  ${BRIGHT_CYAN}${startup_cmd}${NC}"
    echo ""
    echo -e "  ${DIM}Shutdown Command${NC}"
    echo -e "  ${BRIGHT_CYAN}${shutdown_cmd}${NC}"
    echo ""
}

# Function to show edit project screen with current values
# Parameters: current_display, current_start, current_stop
show_edit_project_screen() {
    local current_display="$1"
    local current_start="$2"
    local current_stop="$3"

    clear
    print_header "Edit Project: $current_display"
    echo ""
    echo -e "${BRIGHT_WHITE}Current display name: ${DIM}${current_display}${NC}"
    echo -e "${BRIGHT_WHITE}Current startup cmd:  ${DIM}${current_start}${NC}"
    echo -e "${BRIGHT_WHITE}Current shutdown cmd: ${DIM}${current_stop}${NC}"
    echo ""
}

# Function to show edit project confirmation screen
# Parameters: new_display, new_startup, new_shutdown
show_edit_project_confirmation_screen() {
    local new_display="$1"
    local new_startup="$2"
    local new_shutdown="$3"

    clear
    print_header "Confirm Project Changes"
    echo ""
    echo -e "  ${DIM}Display Name${NC}"
    echo -e "  ${BRIGHT_WHITE}${new_display}${NC}"
    echo ""
    echo -e "  ${DIM}Startup Command${NC}"
    echo -e "  ${BRIGHT_WHITE}${new_startup}${NC}"
    echo ""
    echo -e "  ${DIM}Shutdown Command${NC}"
    echo -e "  ${BRIGHT_WHITE}${new_shutdown}${NC}"
    echo ""
}
