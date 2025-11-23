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

        # Commands section with improved spacing
        echo ""
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
    echo ""
    local counter=1
    for workspace_basename in "${available_workspaces[@]}"; do
        # Construct full path from config_dir and basename
        local workspace_file="$config_dir/$workspace_basename"
        local workspace_name=$(basename "$workspace_basename" .json)
        local display_name=$(echo "$workspace_name" | sed 's/[_-]/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1')

        # Check if workspace is active and display status
        if is_workspace_active "$workspace_file"; then
            # Active workspace - green bullet
            printf "${BRIGHT_CYAN}%s${NC} ${BRIGHT_WHITE}%s${NC} ${BRIGHT_GREEN}●${NC}\n" "$counter" "$display_name"
        else
            # Inactive workspace - dim bullet
            printf "${BRIGHT_CYAN}%s${NC} ${BRIGHT_WHITE}%s${NC} ${DIM}○${NC}\n" "$counter" "$display_name"
        fi

        # Parse projects from this workspace file
        local workspace_projects=()
        if command -v jq >/dev/null 2>&1 && [ -f "$workspace_file" ]; then
            while IFS= read -r line; do
                workspace_projects+=("$line")
            done < <(jq -r '.[] | "\(.displayName):\(.projectName):\(.startupCmd):\(.shutdownCmd)"' "$workspace_file" 2>/dev/null)
        fi

        # Display projects for this workspace
        if [ ${#workspace_projects[@]} -eq 0 ]; then
            echo -e "  ${DIM}No projects configured${NC}"
        else
            for j in "${!workspace_projects[@]}"; do
                IFS=':' read -r project_display_name folder_name startup_cmd shutdown_cmd <<< "${workspace_projects[j]}"

                # Format data with fixed column widths: 32 | 30 | 32 | 32
                local col1="$project_display_name"
                local col2="$folder_name"
                local col3="$startup_cmd"
                local col4="$shutdown_cmd"

                # Truncate if longer than max width
                [ ${#col1} -gt 32 ] && col1=$(printf "%.29s..." "$col1")
                [ ${#col2} -gt 30 ] && col2=$(printf "%.27s..." "$col2")
                [ ${#col3} -gt 32 ] && col3=$(printf "%.29s..." "$col3")
                [ ${#col4} -gt 32 ] && col4=$(printf "%.29s..." "$col4")

                # Ensure fixed width with padding to exact column sizes
                col1=$(printf "%-32.32s" "$col1")
                col2=$(printf "%-30.30s" "$col2")
                col3=$(printf "%-32.32s" "$col3")
                col4=$(printf "%-32.32s" "$col4")

                # Display row with fixed table format - white text for col1, dim for col2-4
                echo -e "  ${BRIGHT_WHITE}${col1}${NC}   ${DIM}${col2}${NC}   ${DIM}${col3}${NC}   ${DIM}${col4}${NC}"
            done
        fi
        echo ""
        counter=$((counter + 1))
    done
}
