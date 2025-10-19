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
        echo ""
        print_header "Settings"

        # Display workspaces from .workspaces.json
        display_workspaces_info

        # Commands section with improved spacing
        echo ""
        print_section_header "Commands"
        echo ""
        echo -e "  ${PURPLE}[a]${NC} Add workspace    ${PURPLE}[m]${NC} Manage workspace    ${PURPLE}[b]${NC} Back    ${PURPLE}[h]${NC} Help"
        echo ""

        # Get user input with better prompt
        echo -ne "${CYAN}❯${NC} "
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
        # Display empty state with better spacing
        echo ""
        print_section_header "Active Workspaces"
        echo ""
        echo -e "  ${DIM}No configured workspaces available${NC}"
        echo ""
        echo -e "  ${DIM}Use '${PURPLE}a${DIM}' to add your first workspace${NC}"
        echo ""
        return 0
    fi

    # Display active workspaces with better formatting
    echo ""
    print_section_header "Active Workspaces"
    echo ""

    local counter=1
    local width=$(get_terminal_width)
    local box_width=$((width - 4))  # Account for padding

    for workspace_file in "${active_workspaces[@]}"; do
        local display_name=$(format_workspace_display_name "$workspace_file")
        local projects_root=$(get_workspace_projects_folder "$workspace_file")

        # Check if file exists
        if [ ! -f "$workspace_file" ]; then
            # Error state
            echo -e "  ${CYAN}╭─${NC} ${BRIGHT_RED}${display_name}${NC} ${RED}(file not found)${NC}"
            echo -e "  ${CYAN}│${NC}  ${DIM}File: ${workspace_file}${NC}"
            echo -e "  ${CYAN}╰─$(printf '─%.0s' $(seq 1 $((box_width - 2))))${NC}"
        else
            # Display workspace card
            echo -e "  ${CYAN}╭─${NC} ${BRIGHT_CYAN}${BOLD}${display_name}${NC}"
            echo -e "  ${CYAN}│${NC}"

            # Location
            if [ -n "$projects_root" ]; then
                echo -e "  ${CYAN}│${NC}  ${DIM}Location${NC}"
                echo -e "  ${CYAN}│${NC}  ${BRIGHT_WHITE}${projects_root}${NC}"
                echo -e "  ${CYAN}│${NC}"
            fi

            # Count projects in this workspace
            local workspace_projects=()
            parse_workspace_projects "$workspace_file" workspace_projects
            local project_count=${#workspace_projects[@]}

            # Projects count
            echo -e "  ${CYAN}│${NC}  ${DIM}Projects${NC}"
            if [ $project_count -gt 0 ]; then
                echo -e "  ${CYAN}│${NC}  ${GREEN}${project_count} configured${NC}"
            else
                echo -e "  ${CYAN}│${NC}  ${DIM}none configured${NC}"
            fi

            echo -e "  ${CYAN}│${NC}"
            echo -e "  ${CYAN}│${NC}  ${DIM}${workspace_file}${NC}"
            echo -e "  ${CYAN}╰─$(printf '─%.0s' $(seq 1 $((box_width - 2))))${NC}"
        fi

        # Add spacing between workspaces
        if [ $counter -lt ${#active_workspaces[@]} ]; then
            echo ""
        fi

        counter=$((counter + 1))
    done
}
