#!/bin/bash

# ========================================
# Projects Module Index
# ========================================
# This module handles project-related operations within workspaces
# Usage: source modules/settings/projects/index.sh

# Get the directory where this script is located
PROJECTS_DIR="$(dirname "${BASH_SOURCE[0]}")"

# Import project components
source "$PROJECTS_DIR/components.sh"

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

# Function to remove a project from a workspace
# Parameters: workspace_file
remove_project_from_workspace() {
    local workspace_file="$1"

    # Set the JSON_CONFIG_FILE for utils functions
    export JSON_CONFIG_FILE="$workspace_file"
    export BACKUP_JSON=false

    clear
    print_header "Remove Project from Workspace"
    echo ""

    # Use helper to select project
    local selected_index
    selected_index=$(select_project_from_workspace "$workspace_file")

    if [ $? -ne 0 ] || [ -z "$selected_index" ]; then
        unset JSON_CONFIG_FILE
        return 0
    fi

    # Get selected project info
    local workspace_projects=()
    parse_workspace_projects "$workspace_file" workspace_projects
    local selected_project="${workspace_projects[selected_index]}"
    IFS=':' read -r proj_display proj_name proj_start proj_stop <<< "$selected_project"

    # Confirm removal
    echo ""
    if prompt_yes_no_confirmation "${BRIGHT_WHITE}Remove project: ${BRIGHT_RED}${proj_display}${NC}?"; then
        # Remove the project using jq
        local temp_file=$(mktemp)

        if jq "del(.[${selected_index}])" "$workspace_file" > "$temp_file"; then
            if mv "$temp_file" "$workspace_file"; then
                echo ""
                print_success "Project removed successfully"
            else
                print_error "Failed to update workspace file"
                rm -f "$temp_file"
            fi
        else
            print_error "Failed to process workspace file"
            rm -f "$temp_file"
        fi
    else
        echo ""
        print_info "Cancelled"
    fi

    unset JSON_CONFIG_FILE
    wait_for_enter
    return 0
}

# Function to edit a project in a workspace
# Parameters: workspace_file
edit_project_in_workspace() {
    local workspace_file="$1"

    # Set the JSON_CONFIG_FILE for utils functions
    export JSON_CONFIG_FILE="$workspace_file"
    export BACKUP_JSON=false

    clear
    print_header "Edit Project in Workspace"
    echo ""

    # Use helper to select project
    local selected_index
    selected_index=$(select_project_from_workspace "$workspace_file")

    if [ $? -ne 0 ] || [ -z "$selected_index" ]; then
        unset JSON_CONFIG_FILE
        return 0
    fi

    # Get selected project info
    local workspace_projects=()
    parse_workspace_projects "$workspace_file" workspace_projects
    local selected_project="${workspace_projects[selected_index]}"
    IFS=':' read -r current_display current_name current_start current_stop <<< "$selected_project"

    # Show edit screen
    show_edit_project_screen "$current_display" "$current_start" "$current_stop"

    # Get new display name
    echo -e "${BRIGHT_WHITE}Enter new display name:${NC}"
    echo -ne "${DIM}(press Enter to keep '$current_display')${NC} ${BRIGHT_CYAN}>${NC} "
    read -r new_display

    if [ -z "$new_display" ]; then
        new_display="$current_display"
    fi

    # Get new startup command
    echo ""
    echo -e "${BRIGHT_WHITE}Enter new startup command:${NC}"
    echo -ne "${DIM}(press Enter to keep current)${NC} ${BRIGHT_CYAN}>${NC} "
    read -r new_startup

    if [ -z "$new_startup" ]; then
        new_startup="$current_start"
    fi

    # Get new shutdown command
    echo ""
    echo -e "${BRIGHT_WHITE}Enter new shutdown command:${NC}"
    echo -ne "${DIM}(press Enter to keep current)${NC} ${BRIGHT_CYAN}>${NC} "
    read -r new_shutdown

    if [ -z "$new_shutdown" ]; then
        new_shutdown="$current_stop"
    fi

    # Show confirmation screen
    show_edit_project_confirmation_screen "$new_display" "$new_startup" "$new_shutdown"

    if prompt_yes_no_confirmation "Save changes?"; then
        # Update the project using jq
        local temp_file=$(mktemp)

        if jq --arg display_name "$new_display" \
              --arg startup_cmd "$new_startup" \
              --arg shutdown_cmd "$new_shutdown" \
              ".[$selected_index].displayName = \$display_name | .[$selected_index].startupCmd = \$startup_cmd | .[$selected_index].shutdownCmd = \$shutdown_cmd" \
              "$workspace_file" > "$temp_file"; then
            if mv "$temp_file" "$workspace_file"; then
                echo ""
                print_success "Project updated successfully"
            else
                print_error "Failed to update workspace file"
                rm -f "$temp_file"
            fi
        else
            print_error "Failed to process workspace file"
            rm -f "$temp_file"
        fi
    else
        echo ""
        print_info "Cancelled"
    fi

    unset JSON_CONFIG_FILE
    wait_for_enter
    return 0
}
