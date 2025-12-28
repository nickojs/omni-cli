#!/bin/bash

# ========================================
# Workspaces Toggle Module
# ========================================
# Handles toggling workspace active/inactive status
# Usage: source modules/settings/workspaces/toggle.sh

# Function to toggle workspace active/inactive status
show_toggle_workspace_menu() {
    # Get all available workspaces
    local available_workspaces=()
    if ! get_available_workspaces available_workspaces || [ ${#available_workspaces[@]} -eq 0 ]; then
        print_error "No workspaces found"
        wait_for_enter
        return 1
    fi

    echo ""
    echo -ne "${BRIGHT_WHITE}Enter workspace number to toggle: ${NC}"
    read -r workspace_choice

    # Handle empty input (cancel)
    if [ -z "$workspace_choice" ]; then
        return 0
    fi

    # Validate input
    if ! [[ "$workspace_choice" =~ ^[0-9]+$ ]] || [ "$workspace_choice" -lt 1 ] || [ "$workspace_choice" -gt "${#available_workspaces[@]}" ]; then
        print_error "Invalid workspace number"
        wait_for_enter
        return 1
    fi

    # Get selected workspace
    local selected_index=$((workspace_choice - 1))
    local selected_workspace_basename="${available_workspaces[selected_index]}"

    # Construct full path from config_dir and basename
    local config_dir=$(get_config_directory)
    local selected_workspace="$config_dir/$selected_workspace_basename"
    local display_name=$(format_workspace_display_name "$selected_workspace")

    # Toggle the workspace
    if is_workspace_active "$selected_workspace"; then
        # Deactivate
        if deactivate_workspace "$selected_workspace"; then
            print_success "Workspace '$display_name' deactivated"
        else
            print_error "Failed to deactivate workspace"
        fi
    else
        # Activate
        local projects_folder=$(get_workspace_projects_folder "$selected_workspace")
        if [ -z "$projects_folder" ]; then
            projects_folder=$(dirname "$selected_workspace")
        fi

        if activate_workspace "$selected_workspace" "$projects_folder"; then
            print_success "Workspace '$display_name' activated"
        else
            print_error "Failed to activate workspace"
        fi
    fi

    return 0
}
