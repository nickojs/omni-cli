#!/bin/bash

# ========================================
# Workspaces Select Module
# ========================================
# Handles workspace selection menu
# Usage: source modules/settings/workspaces/select.sh

# Function to show workspace selection menu
show_workspace_selection_menu() {
    # Show header
    show_workspace_selection_header

    # Get all available workspaces (both active and inactive)
    local available_workspaces=()
    local config_dir=$(get_config_directory)
    local workspaces_file="$config_dir/.workspaces.json"

    if [ ! -f "$workspaces_file" ] || ! get_available_workspaces available_workspaces || [ ${#available_workspaces[@]} -eq 0 ]; then
        print_error "No workspaces found"
        echo ""
        print_info "Add a workspace first using 'a' from the settings menu"
        wait_for_enter
        return 1
    fi

    # Display workspaces
    display_workspace_list available_workspaces

    # Prompt for selection
    echo -ne "${BRIGHT_WHITE}Select workspace: ${BRIGHT_CYAN}"
    read -r workspace_choice
    echo -ne "${NC}"

    # Handle empty input (go back)
    if [ -z "$workspace_choice" ]; then
        return 0
    fi

    # Validate choice
    if ! validate_number_in_range "$workspace_choice" 1 "${#available_workspaces[@]}" "workspace"; then
        wait_for_enter
        return 0
    fi

    # Get selected workspace
    local selected_index=$((workspace_choice - 1))
    local selected_workspace_basename="${available_workspaces[selected_index]}"

    # Construct full path from config_dir and basename
    local selected_workspace="$config_dir/$selected_workspace_basename"

    # Open workspace management screen
    manage_workspace "$selected_workspace"

    return 0
}
