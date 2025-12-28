#!/bin/bash

# ========================================
# Menu Display Module
# ========================================
# This module handles menu display and UI functionality
# Usage: source modules/menu/display.sh

# Function to display menu and start project (for tmux session)
show_project_menu_tmux() {
    # Check if this is first-time setup and show welcome screen
    if is_first_time_setup; then
        show_first_time_welcome
    fi

    while true; do
        clear

        # Clean header
        print_header "Project Manager"

        # Display workspaces
        display_workspaces

        # Commands section with better formatting and grouping
        echo ""

        if [ ${#projects[@]} -eq 0 ]; then
            echo -e "${BRIGHT_PURPLE}s${NC} settings    ${BRIGHT_PURPLE}h${NC} help    ${BRIGHT_PURPLE}q${NC} quit"
        elif [ ${#projects[@]} -eq 1 ]; then
            echo -e "${BRIGHT_GREEN}1${NC} start    ${BRIGHT_YELLOW}c1${NC} terminal    ${BRIGHT_CYAN}r1${NC} restart    ${BRIGHT_RED}k1${NC} kill    ${BRIGHT_PURPLE}s${NC} settings    ${BRIGHT_PURPLE}h${NC} help    ${BRIGHT_PURPLE}q${NC} quit"
        else
            echo -e "${BRIGHT_GREEN}1-${#projects[@]}${NC} start    ${BRIGHT_YELLOW}c1-${#projects[@]}${NC} terminal    ${BRIGHT_CYAN}r1-${#projects[@]}${NC} restart    ${BRIGHT_RED}k1-${#projects[@]}${NC}  ${BRIGHT_RED}ka${NC} kill    ${BRIGHT_PURPLE}s${NC} settings    ${BRIGHT_PURPLE}h${NC} help    ${BRIGHT_PURPLE}q${NC} quit"
        fi

        # Get user input with clean prompt
        echo ""
        echo -ne "${BRIGHT_CYAN}>${NC} "
        read -r choice

        # Handle user input
        handle_menu_choice "$choice"
    done
}

# Function to display active configuration info
show_active_config_info() {
    # Check for bulk config file
    local config_dir=$(get_config_directory)

    local workspaces_file="$config_dir/.workspaces.json"

    if [ -f "$workspaces_file" ] && command -v jq >/dev/null 2>&1; then
        local active_configs=$(jq -r '.activeConfig[]? // empty' "$workspaces_file" 2>/dev/null)
        local projects_path=$(jq -r '.projectsPath // empty' "$workspaces_file" 2>/dev/null)
        local total_configs=$(jq -r '.availableConfigs | length' "$workspaces_file" 2>/dev/null)

        if [ -n "$active_configs" ] && [ -n "$total_configs" ]; then
            # Generate display name from active configs
            local display_name="Active Workspaces"
            if [ -n "$projects_path" ]; then
                echo -e "${BRIGHT_GREEN}●${NC} ${BRIGHT_WHITE}Projects Folder:${NC} ${DIM}${display_name} - ${projects_path}${NC}"
            else
                echo -e "${BRIGHT_GREEN}●${NC} ${BRIGHT_WHITE}Projects Folder:${NC} ${DIM}${display_name}${NC}"
            fi
            echo ""
            return
        elif [ -f "$workspaces_file" ] && [ -n "$total_configs" ] && [ "$total_configs" -gt 0 ]; then
            # Workspaces config exists but no active configs
            echo -e "${BRIGHT_YELLOW}⚠${NC} ${BRIGHT_WHITE}No Active Workspaces:${NC} ${DIM}Configure workspaces in Settings${NC}"
            echo ""
            return
        fi
    fi

    # Fallback display
    local config_name="Default"
    if [ -n "$JSON_CONFIG_FILE" ]; then
        config_name=$(basename "$JSON_CONFIG_FILE" .json)
        config_name=$(echo "$config_name" | sed 's/[_-]/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1')
    fi

    echo -e "${BRIGHT_GREEN}●${NC} ${BRIGHT_WHITE}Projects Folder:${NC} ${DIM}${config_name}${NC}"
    echo ""
}

# Function to display workspaces and their projects with global numbering
display_workspaces() {
    # Check if any projects are loaded globally
    if [ ${#projects[@]} -eq 0 ]; then
        # Clean display for no active workspaces
        echo ""
        echo -e "${WHITE}No workspaces configured.${NC}"
        echo ""
        echo -e "${DIM}Configure workspaces in ${BRIGHT_PURPLE}s${NC} ${DIM}settings menu${NC}"
        echo ""
        return 0
    fi

    # Get config directory
    local config_dir=$(get_config_directory)

    # Get only active workspaces from workspaces config
    local workspace_files=()
    local workspaces_file="$config_dir/.workspaces.json"

    if [ -f "$workspaces_file" ] && command -v jq >/dev/null 2>&1; then
        # Get active workspaces from workspaces config
        while IFS= read -r active_workspace; do
            # Construct full path from config_dir and workspace filename
            local full_workspace_path="$config_dir/$active_workspace"
            if [ -f "$full_workspace_path" ]; then
                workspace_files+=("$full_workspace_path")
            fi
        done < <(jq -r '.activeConfig[]? // empty' "$workspaces_file" 2>/dev/null)
    fi

    local global_counter=1

    # Display each active workspace with its projects using global numbering
    echo ""
    for workspace_file in "${workspace_files[@]}"; do
        local workspace_name=$(basename "$workspace_file" .json)
        local display_name=$(echo "$workspace_name" | sed 's/[_-]/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1')

        # Workspace header matching settings menu style
        printf "${BRIGHT_CYAN}%s${NC}\n" "$display_name"

        # Find projects belonging to this workspace
        local workspace_project_indices=()
        for i in "${!project_workspaces[@]}"; do
            if [[ "${project_workspaces[i]}" == "$workspace_file" ]]; then
                workspace_project_indices+=($i)
            fi
        done

        # Display projects for this workspace
        if [ ${#workspace_project_indices[@]} -eq 0 ]; then
            echo -e "  ${DIM}No projects configured${NC}"
        else
            for j in "${!workspace_project_indices[@]}"; do
                local project_index=${workspace_project_indices[j]}
                IFS=':' read -r project_display_name folder_name startup_cmd shutdown_cmd <<< "${projects[project_index]}"

                # Get status (works for any workspace since we have global project array)
                local status_display=""
                local status_icon=""
                if is_project_running "$project_display_name"; then
                    status_icon="${BRIGHT_GREEN}●${NC}"
                    status_display="${GREEN}running${NC}"
                elif [ -d "$folder_name" ]; then
                    status_icon="${DIM}○${NC}"
                    status_display="${DIM}stopped${NC}"
                else
                    status_icon="${BRIGHT_RED}✗${NC}"
                    status_display="${RED}not found${NC}"
                fi

                # Format project name with fixed width for alignment
                local formatted_name
                if [ ${#project_display_name} -gt 32 ]; then
                    # Truncate long names
                    formatted_name=$(printf "%.29s..." "$project_display_name")
                else
                    # Pad short names to 32 characters
                    formatted_name=$(printf "%-32s" "$project_display_name")
                fi

                # Display project with number and status
                echo -e "  ${BRIGHT_CYAN}${global_counter}${NC} ${BRIGHT_WHITE}${formatted_name}${NC} ${status_display}${NC}"
                global_counter=$((global_counter + 1))
            done
        fi
        echo ""
    done
}

