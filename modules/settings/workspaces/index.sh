#!/bin/bash

# ========================================
# Workspaces Module Index
# ========================================
# This module handles workspace-related operations
# Usage: source modules/settings/workspaces/index.sh

# Get the directory where this script is located
WORKSPACES_DIR="$(dirname "${BASH_SOURCE[0]}")"

# Import workspace components
source "$WORKSPACES_DIR/components.sh"

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
        read -r workspace_name

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

# Function to manage a specific workspace (add projects, etc.)
# Parameters: workspace_file
manage_workspace() {
    local workspace_file="$1"
    local display_name=$(format_workspace_display_name "$workspace_file")

    while true; do
        # Get projects root for this workspace
        local projects_root=$(get_workspace_projects_folder "$workspace_file")

        if [ -z "$projects_root" ]; then
            clear
            print_header "Manage Workspace: $display_name"
            echo ""
            print_error "Could not determine projects folder for this workspace"
            wait_for_enter
            return 1
        fi

        # Count and display projects
        local workspace_projects=()
        parse_workspace_projects "$workspace_file" workspace_projects
        local project_count=${#workspace_projects[@]}

        # Show header
        show_workspace_management_header "$display_name" "$projects_root" "$project_count"

        # Display projects
        display_projects_list workspace_projects

        # Show commands
        show_workspace_management_commands "$project_count"

        # Get user input
        echo -ne "${BRIGHT_CYAN}>${NC} "
        read_with_instant_back choice

        case "${choice,,}" in
            a)
                add_project_to_workspace "$workspace_file" "$projects_root"
                ;;
            e)
                if [ $project_count -gt 0 ]; then
                    edit_project_in_workspace "$workspace_file"
                else
                    print_error "No projects to edit"
                    wait_for_enter
                fi
                ;;
            c)
                if [ $project_count -gt 0 ]; then
                    custom_commands_for_project "$workspace_file"
                else
                    print_error "No projects available"
                    wait_for_enter
                fi
                ;;
            r)
                if [ $project_count -gt 0 ]; then
                    remove_project_from_workspace "$workspace_file"
                else
                    print_error "No projects to remove"
                    wait_for_enter
                fi
                ;;
            d)
                if [ $project_count -eq 0 ]; then
                    if delete_workspace "$workspace_file"; then
                        return 0  # Exit to workspace selection menu
                    fi
                else
                    print_error "Cannot delete workspace with projects. Remove all projects first."
                    wait_for_enter
                fi
                ;;
            b)
                return 0
                ;;
            *)
                print_error "Invalid command"
                wait_for_enter
                ;;
        esac
    done
}


# Function to delete an empty workspace
# Parameters: workspace_file
# Returns: 0 if successful, 1 if error or cancelled
delete_workspace() {
    local workspace_file="$1"
    local display_name=$(format_workspace_display_name "$workspace_file")

    # Show warning
    show_delete_workspace_warning "$display_name" "$workspace_file"

    if prompt_yes_no_confirmation "Are you sure you want to delete this workspace?"; then
        # Remove from configuration (both active and available)
        if unregister_workspace "$workspace_file"; then
            # Delete the workspace file
            if rm -f "$workspace_file" 2>/dev/null; then
                echo ""
                print_success "Workspace deleted successfully"
                wait_for_enter
                return 0
            else
                echo ""
                print_error "Failed to delete workspace file"
                wait_for_enter
                return 1
            fi
        else
            echo ""
            print_error "Failed to remove workspace from configuration"
            wait_for_enter
            return 1
        fi
    else
        echo ""
        print_info "Cancelled"
        wait_for_enter
        return 1
    fi
}

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
