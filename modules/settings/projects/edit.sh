#!/bin/bash

# ========================================
# Projects Edit Module
# ========================================
# Handles editing projects in workspaces
# Usage: source modules/settings/projects/edit.sh

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
