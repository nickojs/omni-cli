#!/bin/bash

# ========================================
# Workspaces Add Module
# ========================================
# Handles adding and creating workspaces
# Usage: source modules/settings/workspaces/add.sh

# Function to show add workspace screen - launches filesystem navigator
show_add_workspace_screen() {
    # Call the filesystem navigator to select a directory
    show_path_selector

    # Check if a directory was selected
    if [ -n "$SELECTED_PROJECTS_DIR" ]; then
        local projects_folder="$SELECTED_PROJECTS_DIR"
        local default_name=$(basename "$projects_folder")

        # Show workspace name prompt
        show_workspace_name_prompt "$projects_folder" "$default_name"
        local workspace_name
        read_with_esc_cancel workspace_name
        local read_result=$?

        # Handle Esc key - return to previous screen
        if [ $read_result -eq 2 ]; then
            unset SELECTED_PROJECTS_DIR
            return 0
        fi

        # Use default if empty
        if [ -z "$workspace_name" ]; then
            workspace_name="$default_name"
        fi

        # Validate workspace name
        if ! [[ "$workspace_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            print_error "Invalid workspace name. Use only letters, numbers, dashes, and underscores."
            wait_for_enter
            unset SELECTED_PROJECTS_DIR
            return 1
        fi

        # Create workspace
        if create_workspace "$workspace_name" "$projects_folder"; then
            show_workspace_created_screen "$workspace_name" "$projects_folder"
            wait_for_enter
        else
            print_error "Failed to create workspace."
            wait_for_enter
        fi

        unset SELECTED_PROJECTS_DIR
    fi
}

# Function to create a new workspace
# Parameters: workspace_name, projects_folder
# Returns: 0 if successful, 1 if error
create_workspace() {
    local workspace_name="$1"
    local projects_folder="$2"

    # Get config directory
    local config_dir=$(get_config_directory)

    # Ensure config directory exists
    if [ ! -d "$config_dir" ]; then
        mkdir -p "$config_dir" 2>/dev/null || return 1
    fi

    # Create workspace file path
    local workspace_file="$config_dir/${workspace_name}.json"

    # Check if workspace file already exists
    if [ -f "$workspace_file" ]; then
        print_error "Workspace '$workspace_name' already exists!"
        return 1
    fi

    # Create empty workspace file (empty JSON array)
    if ! echo '[]' > "$workspace_file" 2>/dev/null; then
        print_error "Failed to create workspace file: $workspace_file"
        return 1
    fi

    # Register the workspace (add to availableConfigs but not activeConfig - starts inactive)
    if ! register_workspace "$workspace_file" "$projects_folder"; then
        print_error "Failed to register workspace in configuration"
        rm -f "$workspace_file" 2>/dev/null
        return 1
    fi

    return 0
}
