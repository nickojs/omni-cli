#!/bin/bash

# ========================================
# Projects Add Module
# ========================================
# Handles adding projects to workspaces
# Usage: source modules/settings/projects/add.sh

# Function to add a project to a workspace
# Parameters: workspace_file, projects_root
add_project_to_workspace() {
    local workspace_file="$1"
    local projects_root="$2"

    # Set the JSON_CONFIG_FILE for utils functions
    export JSON_CONFIG_FILE="$workspace_file"
    export BACKUP_JSON=false

    clear
    print_header "Add Project to Workspace"

    # Create a check function for folder managed status
    check_folder_managed() {
        local folder_name="$1"
        is_folder_managed "$folder_name" "$projects_root"
    }

    # Scan and let user select a folder
    local selected_folder
    selected_folder=$(scan_and_display_available_folders "$projects_root" check_folder_managed)
    local scan_result=$?

    if [ $scan_result -ne 0 ] || [ -z "$selected_folder" ]; then
        unset JSON_CONFIG_FILE
        return 1
    fi

    # Show configuration screen
    show_project_configuration_screen "$selected_folder" "$projects_root"

    # Prompt for project fields
    local temp_config_file=$(mktemp)
    prompt_project_input_fields "$selected_folder" > "$temp_config_file"

    # Read the three lines from temp file
    local display_name startup_cmd shutdown_cmd
    {
        read -r display_name
        read -r startup_cmd
        read -r shutdown_cmd
    } < "$temp_config_file"
    rm -f "$temp_config_file"

    # Show confirmation screen
    show_project_confirmation_screen "$display_name" "$selected_folder" "$startup_cmd" "$shutdown_cmd"

    # Confirm
    if prompt_yes_no_confirmation "Add this project to workspace?"; then
        echo ""
        add_project_to_config "$display_name" "$selected_folder" "$projects_root" "$startup_cmd" "$shutdown_cmd"
    else
        echo ""
        print_info "Cancelled"
    fi

    unset JSON_CONFIG_FILE
    wait_for_enter
    return 0
}
