#!/bin/bash

# ========================================
# Settings Menu Display Module
# ========================================
# This module handles settings menu display and UI functionality
# Usage: source modules/settings/display.sh

# Interactive settings menu with command handling
show_settings_menu() {
    # Check if any projects are running
    local running_projects
    running_projects=$(list_project_panes)

    if [[ -n "$running_projects" ]]; then
        clear
        print_header "Settings"
        echo ""
        print_error "Cannot access settings while projects are running"
        echo ""
        wait_for_enter
        return 0
    fi

    while true; do
        clear
        print_header "Settings"

        # Display workspaces from .workspaces.json
        display_workspaces_info

        echo -e "${BRIGHT_GREEN}a${NC} add workspace    ${BRIGHT_GREEN}m${NC} manage workspace    ${BRIGHT_BLUE}t${NC} toggle workspace    ${BRIGHT_PURPLE}b${NC} back    ${BRIGHT_PURPLE}h${NC} help"
        echo ""

        # Get user input with better prompt
        echo -ne "${BRIGHT_CYAN}>${NC} "
        read_with_instant_back choice

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

    # Get all available workspaces
    local available_workspaces=()
    if [ ! -f "$workspaces_file" ] || ! get_available_workspaces available_workspaces || [ ${#available_workspaces[@]} -eq 0 ]; then
        # Display empty state with better spacing
        echo ""
        echo -e "${BRIGHT_YELLOW}No workspaces configured.${NC}"
        echo ""
        return 0
    fi

    # Display all workspaces (both active and inactive) as numbered list
    # Table header
    printf "${BOLD}%-3s %-32s %-15s %-16s %-16s %-8s${NC}\n" "#" "display name" "folder" "startup cmd" "shutdown cmd" "has custom cmd"
    echo ""

    local counter=1
    for workspace_basename in "${available_workspaces[@]}"; do
        # Construct full path from config_dir and basename
        local workspace_file="$config_dir/$workspace_basename"
        local workspace_name=$(basename "$workspace_basename" .json)
        local display_name=$(echo "$workspace_name" | sed 's/[_-]/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1')

        # Workspace row in table format
        local status_icon=""
        if is_workspace_active "$workspace_file"; then
            status_icon="${BRIGHT_GREEN}●${NC}"
        else
            status_icon="${DIM}○${NC}"
        fi
        printf "${BRIGHT_CYAN}%-3s${NC} ${BOLD}%-32s${NC} ${DIM}%-15s %-16s %-16s %-8s${NC}\n" "$counter" "$display_name $status_icon" "" "" "" ""

        # Parse projects from this workspace file
        local workspace_projects=()
        if command -v jq >/dev/null 2>&1 && [ -f "$workspace_file" ]; then
            while IFS= read -r line; do
                workspace_projects+=("$line")
            done < <(jq -r '.[] | "\(.displayName):\(.projectName):\(.startupCmd):\(.shutdownCmd):\(if .customCommands and (.customCommands | length) > 0 then "true" else "false" end)"' "$workspace_file" 2>/dev/null)
        fi

        # Display projects for this workspace
        if [ ${#workspace_projects[@]} -eq 0 ]; then
            printf "${DIM}%-3s %-32s %-15s %-16s %-16s %-8s${NC}\n" "" "No projects configured" "" "" "" ""
            echo ""
        else
            for j in "${!workspace_projects[@]}"; do
                IFS=':' read -r project_display_name folder_name startup_cmd shutdown_cmd has_custom_cmd <<< "${workspace_projects[j]}"

                # Truncate if longer than max width
                [ ${#project_display_name} -gt 32 ] && project_display_name=$(printf "%.29s..." "$project_display_name")
                [ ${#folder_name} -gt 15 ] && folder_name=$(printf "%.12s..." "$folder_name")
                [ ${#startup_cmd} -gt 16 ] && startup_cmd=$(printf "%.13s..." "$startup_cmd")
                [ ${#shutdown_cmd} -gt 16 ] && shutdown_cmd=$(printf "%.13s..." "$shutdown_cmd")

                # Display row with proper table alignment
                printf "%-3s ${BRIGHT_WHITE}%-32s${NC} ${DIM}%-15s %-16s %-16s %-8s${NC}\n" "" "$project_display_name" "$folder_name"/ "$startup_cmd" "$shutdown_cmd" "$has_custom_cmd"
            done
                echo ""
        fi
        counter=$((counter + 1))
    done
}
