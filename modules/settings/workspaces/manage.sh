#!/bin/bash

# ========================================
# Workspaces Manage Module
# ========================================
# Handles workspace management operations
# Usage: source modules/settings/workspaces/manage.sh

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
