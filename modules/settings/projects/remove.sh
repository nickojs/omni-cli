#!/bin/bash

# ========================================
# Projects Remove Module
# ========================================
# Handles removing projects from workspaces
# Usage: source modules/settings/projects/remove.sh

# Function to remove a project from a workspace
# Parameters: workspace_file, project_index
remove_project_from_workspace() {
    local workspace_file="$1"
    local selected_index="$2"

    # Set the JSON_CONFIG_FILE for utils functions
    export JSON_CONFIG_FILE="$workspace_file"
    export BACKUP_JSON=false

    # Get selected project info
    local workspace_projects=()
    parse_workspace_projects "$workspace_file" workspace_projects
    local selected_project="${workspace_projects[selected_index]}"
    IFS=':' read -r proj_display proj_name proj_start proj_stop <<< "$selected_project"

    clear
    print_header "Remove Project"
    echo ""
    echo -e "  ${BRIGHT_WHITE}${proj_display}${NC} ${DIM}(${proj_name})${NC}"
    echo ""

    # Confirm removal
    if prompt_yes_no_confirmation "${BRIGHT_WHITE}Remove this project?${NC}"; then
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
