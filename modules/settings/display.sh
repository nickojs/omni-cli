#!/bin/bash

# ========================================
# Settings Menu Display Module
# ========================================
# This module handles settings menu display and UI functionality
# Usage: source modules/settings/display.sh

# Global array to store available workspaces for command routing
declare -a settings_workspaces=()

# Interactive settings menu with command handling
show_settings_menu() {
    # Check if any projects are running - determines restricted mode
    local running_projects
    running_projects=$(list_project_panes)

    local restricted_mode=false
    if [[ -n "$running_projects" ]]; then
        restricted_mode=true
    fi

    while true; do
        printf '\033[?25l'  # Hide cursor during redraw
        clear
        print_header "Settings"

        # Show restricted mode indicator if applicable
        if [[ "$restricted_mode" == true ]]; then
            echo -e "${BRIGHT_YELLOW}(Restricted Mode - projects running)${NC}"
        fi

        # Display workspaces from .workspaces.json (also populates settings_workspaces)
        display_workspaces_info

        # Build workspace command displays based on workspace count and mode
        local manage_cmd=""
        local toggle_cmd=""
        local add_cmd=""

        if [ ${#settings_workspaces[@]} -gt 0 ]; then
            # Toggle is always available
            if [ ${#settings_workspaces[@]} -eq 1 ]; then
                toggle_cmd="${BRIGHT_BLUE}t1${NC} toggle workspace"
            else
                toggle_cmd="${BRIGHT_BLUE}t1-t${#settings_workspaces[@]}${NC} toggle workspace"
            fi

            # Manage only in unrestricted mode
            if [[ "$restricted_mode" != true ]]; then
                if [ ${#settings_workspaces[@]} -eq 1 ]; then
                    manage_cmd="${BRIGHT_GREEN}m1${NC} manage workspace"
                else
                    manage_cmd="${BRIGHT_GREEN}m1-m${#settings_workspaces[@]}${NC} manage workspace"
                fi
            fi
        fi

        # Add only in unrestricted mode
        if [[ "$restricted_mode" != true ]]; then
            add_cmd="${BRIGHT_GREEN}a${NC} add workspace"
        fi

        local secrets_cmd="${BRIGHT_YELLOW}s${NC} secrets"

        # Display command line based on mode
        echo ""
        if [[ "$restricted_mode" == true ]]; then
            # Restricted mode: only toggle, secrets, navigation, and help
            if [ -n "$toggle_cmd" ]; then
                echo -e "${toggle_cmd}    ${secrets_cmd}    ${BRIGHT_PURPLE}b${NC} back    ${BRIGHT_PURPLE}h${NC} help"
            else
                echo -e "${secrets_cmd}    ${BRIGHT_PURPLE}b${NC} back    ${BRIGHT_PURPLE}h${NC} help"
            fi
        else
            # Full mode: all commands
            if [ -n "$manage_cmd" ]; then
                echo -e "${add_cmd}    ${manage_cmd}    ${toggle_cmd}    ${secrets_cmd}    ${BRIGHT_PURPLE}b${NC} back    ${BRIGHT_PURPLE}h${NC} help"
            else
                echo -e "${add_cmd}    ${secrets_cmd}    ${BRIGHT_PURPLE}b${NC} back    ${BRIGHT_PURPLE}h${NC} help"
            fi
        fi
        echo ""

        # Get user input with better prompt
        printf '\033[?25h'  # Show cursor for input
        echo -ne "${BRIGHT_CYAN}>${NC} "
        read_with_instant_back choice

        # Handle user input - pass restricted_mode flag
        handle_settings_choice "$choice" "$restricted_mode"
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

    # Reset global workspaces array
    settings_workspaces=()

    # Get all available workspaces
    local available_workspaces=()
    if [ ! -f "$workspaces_file" ] || ! get_available_workspaces available_workspaces || [ ${#available_workspaces[@]} -eq 0 ]; then
        echo ""
        echo -e "${WHITE}No workspaces configured.${NC}"
        echo ""
        echo -e "${DIM}Use ${BRIGHT_GREEN}a${NC} ${DIM}to add a workspace${NC}"
        echo ""
        return 0
    fi

    # Populate global array for command routing
    settings_workspaces=("${available_workspaces[@]}")

    echo ""

    local counter=1
    for workspace_basename in "${available_workspaces[@]}"; do
        local workspace_file="$config_dir/$workspace_basename"
        local display_name=$(format_workspace_display_name "$workspace_file")

        # Get workspace status using shared component
        local status_result=$(get_workspace_status "$workspace_file")
        local status_icon="${status_result%%|*}"
        local status_text="${status_result#*|}"

        # Render workspace header and table header
        render_workspace_header "settings" "$display_name" "$counter" "$status_icon" "$status_text"
        render_table_header "settings"

        # Parse projects from this workspace file
        local workspace_projects=()
        if command -v jq >/dev/null 2>&1 && [ -f "$workspace_file" ]; then
            while IFS= read -r line; do
                workspace_projects+=("$line")
            done < <(jq -r '.[] | "\(.displayName):\(.projectName):\(.relativePath):\(.startupCmd // ""):\(.shutdownCmd // "")"' "$workspace_file" 2>/dev/null)
        fi

        # Display projects for this workspace
        if [ ${#workspace_projects[@]} -eq 0 ]; then
            echo -e "  ${DIM}No projects configured${NC}"
        else
            for project_info in "${workspace_projects[@]}"; do
                IFS=':' read -r project_display_name folder_name relative_path startup_cmd shutdown_cmd <<< "$project_info"

                # Use dash for empty values
                [[ -z "$startup_cmd" || "$startup_cmd" == "null" ]] && startup_cmd="—"
                [[ -z "$shutdown_cmd" || "$shutdown_cmd" == "null" ]] && shutdown_cmd="—"

                # Get vaults using shared component
                local vault_text=$(get_project_vaults "$workspace_file" "$relative_path")

                # Render row using shared component
                render_settings_project_row "$project_display_name" "$folder_name" "$startup_cmd" "$shutdown_cmd" "$vault_text"
            done
            echo ""
        fi
        echo ""
        counter=$((counter + 1))
    done
}
 