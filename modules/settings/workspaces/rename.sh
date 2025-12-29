#!/bin/bash

# ========================================
# Workspaces Rename Module
# ========================================
# Handles workspace renaming
# Usage: source modules/settings/workspaces/rename.sh

# Global variable to store renamed workspace path
declare -g RENAMED_WORKSPACE_FILE=""

# Function to rename a workspace
# Parameters: workspace_file, current_display_name
# Sets RENAMED_WORKSPACE_FILE on success
rename_workspace() {
    local workspace_file="$1"
    local current_display="$2"

    # Clear global result
    RENAMED_WORKSPACE_FILE=""

    clear
    print_header "Rename Workspace"
    echo ""
    echo -e "${BRIGHT_WHITE}Current name: ${DIM}${current_display}${NC}"
    echo ""
    echo -e "${DIM}Press Esc to cancel${NC}"
    echo ""
    echo -e "${BRIGHT_WHITE}Enter new workspace name:${NC}"
    echo -ne "${BRIGHT_CYAN}>${NC} "

    local new_name
    read_with_esc_cancel new_name
    local read_result=$?

    # Handle Esc key
    if [ $read_result -eq 2 ]; then
        return 0
    fi

    # If empty, cancel
    if [ -z "$new_name" ]; then
        echo ""
        print_info "Cancelled (no name entered)"
        wait_for_enter
        return 0
    fi

    # Validate workspace name
    if ! [[ "$new_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo ""
        print_error "Invalid name. Use only letters, numbers, dashes, and underscores."
        wait_for_enter
        return 0
    fi

    # Check if same name
    if [ "$new_name" = "$current_display" ]; then
        echo ""
        print_info "Name unchanged"
        wait_for_enter
        return 0
    fi

    # Get config directory and check if new file would conflict
    local config_dir=$(get_config_directory)
    local old_basename=$(basename "$workspace_file")
    local new_basename="${new_name}.json"
    local new_workspace_file="$config_dir/$new_basename"

    if [ -f "$new_workspace_file" ]; then
        echo ""
        print_error "A workspace named '$new_name' already exists"
        wait_for_enter
        return 0
    fi

    # Get the projects folder before renaming
    local projects_folder=$(get_workspace_projects_folder "$workspace_file")
    local was_active=false
    if is_workspace_active "$workspace_file"; then
        was_active=true
    fi

    # Rename the file
    if ! mv "$workspace_file" "$new_workspace_file" 2>/dev/null; then
        echo ""
        print_error "Failed to rename workspace file"
        wait_for_enter
        return 0
    fi

    # Update .workspaces.json
    local workspaces_file=$(get_workspaces_file_path)

    if command -v jq >/dev/null 2>&1; then
        json_update_file "$workspaces_file" \
            '.availableConfigs = [.availableConfigs[] | if . == $old then $new else . end] |
             .activeConfig = [.activeConfig[] | if . == $old then $new else . end] |
             .workspacePaths = (.workspacePaths | to_entries | map(if .key == $old then .key = $new else . end) | from_entries)' \
            --arg old "$old_basename" \
            --arg new "$new_basename"
    fi

    echo ""
    print_success "Workspace renamed to '$new_name'"
    wait_for_enter

    # Set global variable for caller to use
    RENAMED_WORKSPACE_FILE="$new_workspace_file"
}
