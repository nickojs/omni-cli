#!/bin/bash

# ========================================
# Settings Menu Display Module
# ========================================
# This module handles settings menu display and UI functionality
# Usage: source modules/settings/display.sh

# Interactive settings menu with command handling
show_settings_menu() {
    while true; do
        clear
        print_header "Settings"
        echo ""

        # Display workspaces from .workspaces.json
        display_workspaces_info

        # Commands section
        echo ""
        print_section_header "Commands"
        echo ""
        echo -e "  ${PURPLE}a${NC} add workspace  ${CYAN}│${NC}  ${PURPLE}b${NC} back  ${CYAN}│${NC}  ${PURPLE}h${NC} help"

        # Get user input
        echo ""
        echo -ne "${BLUE}❯${NC} "
        read -r choice

        # Handle user input
        handle_settings_choice "$choice"
        local result=$?

        # Exit loop if back was selected
        if [ $result -eq 1 ]; then
            break
        fi
    done
}

# Function to display workspaces information
display_workspaces_info() {
    local config_dir=$(get_config_directory)
    local workspaces_file="$config_dir/.workspaces.json"

    # Check if workspaces file exists or has active workspaces
    local active_workspaces=()
    if [ ! -f "$workspaces_file" ] || ! get_active_workspaces active_workspaces || [ ${#active_workspaces[@]} -eq 0 ]; then
        # Display empty state message
        echo -e "${DIM}No configured workspaces available${NC}"
        return 0
    fi

    # Display active workspaces with better formatting
    print_section_header "Active Workspaces"
    echo ""

    local counter=1
    for workspace_file in "${active_workspaces[@]}"; do
        local display_name=$(format_workspace_display_name "$workspace_file")
        local projects_root=$(get_workspace_projects_folder "$workspace_file")

        # Check if file exists
        if [ ! -f "$workspace_file" ]; then
            echo -e "${CYAN}╭─${NC} ${BRIGHT_RED}${display_name}${NC} ${RED}(file not found)${NC}"
            echo -e "${CYAN}│${NC} ${DIM}File: ${workspace_file}${NC}"
            echo -e "${CYAN}╰$(printf '─%.0s' $(seq 1 66))╯${NC}"
        else
            echo -e "${CYAN}╭─${NC} ${BRIGHT_CYAN}${display_name}${NC}"

            if [ -n "$projects_root" ]; then
                echo -e "${CYAN}│${NC} ${BRIGHT_WHITE}Location:${NC} ${DIM}${projects_root}${NC}"
            fi

            # Count projects in this workspace
            local workspace_projects=()
            parse_workspace_projects "$workspace_file" workspace_projects
            local project_count=${#workspace_projects[@]}

            if [ $project_count -gt 0 ]; then
                echo -e "${CYAN}│${NC} ${BRIGHT_WHITE}Projects:${NC} ${GREEN}${project_count}${NC}"
            else
                echo -e "${CYAN}│${NC} ${BRIGHT_WHITE}Projects:${NC} ${DIM}none configured${NC}"
            fi

            echo -e "${CYAN}│${NC} ${DIM}${workspace_file}${NC}"
            echo -e "${CYAN}╰$(printf '─%.0s' $(seq 1 66))╯${NC}"
        fi

        echo ""
        counter=$((counter + 1))
    done

    # Show workspaces file location with subtle styling
    echo -e "${CYAN}─── Configuration ─────────────────────────────────────────────${NC}"
    echo -e "${DIM}${workspaces_file}${NC}"
}
