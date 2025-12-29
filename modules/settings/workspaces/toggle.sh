#!/bin/bash

# ========================================
# Workspaces Toggle Module
# ========================================
# Handles toggling workspace active/inactive status
# Usage: source modules/settings/workspaces/toggle.sh

# Function to toggle workspace active/inactive status
# Parameters: workspace_file, restricted_mode (optional)
toggle_workspace() {
    local workspace_file="$1"
    local restricted_mode="${2:-false}"
    local display_name=$(format_workspace_display_name "$workspace_file")

    # Check current state
    if is_workspace_active "$workspace_file"; then
        # Attempting to deactivate - blocked in restricted mode
        if [[ "$restricted_mode" == true ]]; then
            print_error "Cannot deactivate workspace while projects are running"
            wait_for_enter
            return 1
        fi

        # Deactivate (unrestricted mode only)
        if deactivate_workspace "$workspace_file"; then
            print_success "Workspace '$display_name' deactivated"
        else
            print_error "Failed to deactivate workspace"
        fi
    else
        # Activate - always allowed
        local projects_folder=$(get_workspace_projects_folder "$workspace_file")
        if [ -z "$projects_folder" ]; then
            projects_folder=$(dirname "$workspace_file")
        fi

        if activate_workspace "$workspace_file" "$projects_folder"; then
            print_success "Workspace '$display_name' activated"
        else
            print_error "Failed to activate workspace"
        fi
    fi

    return 0
}
