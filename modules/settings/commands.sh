#!/bin/bash

# ========================================
# Settings Commands Module
# ========================================
# This module handles settings menu command routing and processing
# Usage: source modules/settings/commands.sh

# Function to handle settings menu choices
handle_settings_choice() {
    local choice="$1"

    # Handle back command
    if [[ $choice =~ ^[Bb]$ ]]; then
        return 1  # Return to previous menu
    fi

    # Handle help command
    if [[ $choice =~ ^[Hh]$ ]]; then
        show_settings_help
        return 0
    fi

    # Handle add workspace command
    if [[ $choice =~ ^[Aa]$ ]]; then
        show_add_workspace_screen
        return 0
    fi

    # Handle manage workspace command
    if [[ $choice =~ ^[Mm]$ ]]; then
        show_workspace_selection_menu
        return 0
    fi

    # Invalid command
    print_error "Invalid command. Use a (add workspace), m (manage workspace), b (back) or h (help)"
    echo -ne "${BRIGHT_YELLOW}Press Enter to continue...${NC}"
    read -r
    return 0
}

# Function to show add workspace screen - launches filesystem navigator
show_add_workspace_screen() {
    # Call the filesystem navigator to select a directory
    show_path_selector

    # Check if a directory was selected
    if [ -n "$SELECTED_PROJECTS_DIR" ]; then
        # Store the selected directory
        local projects_folder="$SELECTED_PROJECTS_DIR"

        # Prompt for workspace name
        clear
        print_header "Create Workspace"
        echo ""
        print_success "Directory selected: $projects_folder"
        echo ""

        # Get default name from directory basename
        local default_name=$(basename "$projects_folder")

        # Prompt for workspace name
        echo -e "${BRIGHT_WHITE}Enter name for this workspace:${NC}"
        echo -ne "${DIM}(press Enter to use '$default_name')${NC} ${BLUE}❯${NC} "
        read -r workspace_name

        # Use default if empty
        if [ -z "$workspace_name" ]; then
            workspace_name="$default_name"
        fi

        # Validate workspace name (alphanumeric, dash, underscore only)
        if ! [[ "$workspace_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            print_error "Invalid workspace name. Use only letters, numbers, dashes, and underscores."
            echo -ne "${BRIGHT_YELLOW}Press Enter to continue...${NC}"
            read -r
            unset SELECTED_PROJECTS_DIR
            return 1
        fi

        # Create workspace
        if create_workspace "$workspace_name" "$projects_folder"; then
            clear
            print_header "Workspace Created"
            echo ""
            print_success "Workspace '$workspace_name' created successfully!"
            echo ""
            print_info "Projects folder: $projects_folder"
            print_info "You can now add projects to this workspace."
            echo ""
            echo -ne "${BRIGHT_YELLOW}Press Enter to continue...${NC}"
            read -r
        else
            print_error "Failed to create workspace."
            echo -ne "${BRIGHT_YELLOW}Press Enter to continue...${NC}"
            read -r
        fi

        # Clear the selection for next time
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

    # Activate the workspace (registers and activates in one step)
    if ! activate_workspace "$workspace_file" "$projects_folder"; then
        print_error "Failed to register workspace in configuration"
        # Clean up the workspace file we just created
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
        clear
        print_header "Manage Workspace: $display_name"
        echo ""

        # Get projects root for this workspace
        local projects_root=$(get_workspace_projects_folder "$workspace_file")

        if [ -z "$projects_root" ]; then
            print_error "Could not determine projects folder for this workspace"
            wait_for_enter
            return 1
        fi

        # Count and display projects
        local workspace_projects=()
        parse_workspace_projects "$workspace_file" workspace_projects
        local project_count=${#workspace_projects[@]}

        if [ $project_count -gt 0 ]; then
            echo -e "  ${BRIGHT_WHITE}Projects (${project_count})"

            for project_info in "${workspace_projects[@]}"; do
                IFS=':' read -r proj_display proj_name proj_start proj_stop <<< "$project_info"
                echo -e "    ${BRIGHT_CYAN}•${NC} ${BRIGHT_WHITE}${proj_display}${NC} ${DIM}(${proj_name})${NC}"
            done
            echo ""
        else
            echo -e "  ${DIM}No projects configured yet${NC}"
            echo ""
        fi

        # Commands
        echo ""
        if [ $project_count -gt 0 ]; then
            echo -e "${BRIGHT_GREEN}[a]${NC} add project │ ${BRIGHT_YELLOW}[e]${NC} edit project │ ${BRIGHT_RED}[r]${NC} remove project │ ${BRIGHT_PURPLE}[b]${NC} back │ ${BRIGHT_PURPLE}[h]${NC} help"
        else
            echo -e "${BRIGHT_GREEN}[a]${NC} add project │ ${BRIGHT_RED}[d]${NC} delete workspace │ ${BRIGHT_PURPLE}[b]${NC} back │ ${BRIGHT_PURPLE}[h]${NC} help"
        fi
        echo ""

        # Get user input
        echo -ne "${BRIGHT_CYAN}>${NC} "
        read -r choice

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
            h)
                show_workspace_management_help
                ;;
            *)
                print_error "Invalid command"
                wait_for_enter
                ;;
        esac
    done
}

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
    # Call the function normally - it handles its own I/O and returns the folder via stdout
    local selected_folder
    selected_folder=$(scan_and_display_available_folders "$projects_root" check_folder_managed)
    local scan_result=$?

    if [ $scan_result -ne 0 ] || [ -z "$selected_folder" ]; then
        # User cancelled or error occurred
        unset JSON_CONFIG_FILE
        return 1
    fi

    # Get project configuration from user
    clear
    print_header "Configure Project"
    echo ""
    echo -e "${BRIGHT_CYAN}Adding project:${NC} ${BRIGHT_WHITE}${selected_folder}${NC}"
    echo -e "${DIM}Location: ${projects_root%/}/${selected_folder}${NC}"
    echo ""

    # Prompt for project fields - call function and capture output to temp file
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

    # Show configuration summary
    clear
    print_header "Confirm Project Configuration"
    echo ""
    echo -e "  ${DIM}Display Name${NC}"
    echo -e "  ${BRIGHT_WHITE}${display_name}${NC}"
    echo ""
    echo -e "  ${DIM}Folder${NC}"
    echo -e "  ${BRIGHT_CYAN}${selected_folder}${NC}"
    echo ""
    echo -e "  ${DIM}Location${NC}"
    echo -e "  ${DIM}${projects_root%/}/${selected_folder}${NC}"
    echo ""
    echo -e "  ${DIM}Startup Command${NC}"
    echo -e "  ${BRIGHT_YELLOW}${startup_cmd}${NC}"
    echo ""
    echo -e "  ${DIM}Shutdown Command${NC}"
    echo -e "  ${BRIGHT_YELLOW}${shutdown_cmd}${NC}"
    echo ""

    # Confirm
    if prompt_yes_no_confirmation "Add this project to workspace?"; then
        echo ""
        # add_project_to_config already prints success/error message
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

    # Get projects from workspace
    local workspace_projects=()
    parse_workspace_projects "$workspace_file" workspace_projects

    if [ ${#workspace_projects[@]} -eq 0 ]; then
        print_error "No projects in this workspace"
        unset JSON_CONFIG_FILE
        wait_for_enter
        return 1
    fi

    # Display projects with numbers
    echo -e "${BRIGHT_WHITE}Select a project to remove:${NC}"
    echo ""

    local counter=1
    for project_info in "${workspace_projects[@]}"; do
        IFS=':' read -r proj_display proj_name proj_start proj_stop <<< "$project_info"
        echo -e "  ${BRIGHT_CYAN}${counter}.${NC} ${BRIGHT_WHITE}${proj_display}${NC} ${DIM}(${proj_name})${NC}"
        counter=$((counter + 1))
    done

    echo ""
    echo -ne "${BRIGHT_WHITE}Enter project number (or press Enter to cancel): ${NC}"
    read -r project_choice

    # Handle empty input (cancel)
    if [ -z "$project_choice" ]; then
        unset JSON_CONFIG_FILE
        return 0
    fi

    # Validate choice is a number
    if ! [[ "$project_choice" =~ ^[0-9]+$ ]]; then
        print_error "Invalid choice. Please enter a number."
        unset JSON_CONFIG_FILE
        wait_for_enter
        return 1
    fi

    # Validate choice is in range
    if [ "$project_choice" -lt 1 ] || [ "$project_choice" -gt "${#workspace_projects[@]}" ]; then
        print_error "Invalid choice. Please select a number between 1 and ${#workspace_projects[@]}."
        unset JSON_CONFIG_FILE
        wait_for_enter
        return 1
    fi

    # Get selected project info
    local selected_index=$((project_choice - 1))
    local selected_project="${workspace_projects[selected_index]}"
    IFS=':' read -r proj_display proj_name proj_start proj_stop <<< "$selected_project"

    # Confirm removal
    echo ""
    echo -e "${BRIGHT_WHITE}Remove project: ${BRIGHT_RED}${proj_display}${NC} ${DIM}(${proj_name})${NC}?"

    if prompt_yes_no_confirmation "Are you sure?"; then
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

    # Get projects from workspace
    local workspace_projects=()
    parse_workspace_projects "$workspace_file" workspace_projects

    if [ ${#workspace_projects[@]} -eq 0 ]; then
        print_error "No projects in this workspace"
        unset JSON_CONFIG_FILE
        wait_for_enter
        return 1
    fi

    # Display projects with numbers
    echo -e "${BRIGHT_WHITE}Select a project to edit:${NC}"
    echo ""

    local counter=1
    for project_info in "${workspace_projects[@]}"; do
        IFS=':' read -r proj_display proj_name proj_start proj_stop <<< "$project_info"
        echo -e "  ${BRIGHT_CYAN}${counter}.${NC} ${BRIGHT_WHITE}${proj_display}${NC} ${DIM}(${proj_name})${NC}"
        counter=$((counter + 1))
    done

    echo ""
    echo -ne "${BRIGHT_WHITE}Enter project number (or press Enter to cancel): ${NC}"
    read -r project_choice

    # Handle empty input (cancel)
    if [ -z "$project_choice" ]; then
        unset JSON_CONFIG_FILE
        return 0
    fi

    # Validate choice is a number
    if ! [[ "$project_choice" =~ ^[0-9]+$ ]]; then
        print_error "Invalid choice. Please enter a number."
        unset JSON_CONFIG_FILE
        wait_for_enter
        return 1
    fi

    # Validate choice is in range
    if [ "$project_choice" -lt 1 ] || [ "$project_choice" -gt "${#workspace_projects[@]}" ]; then
        print_error "Invalid choice. Please select a number between 1 and ${#workspace_projects[@]}."
        unset JSON_CONFIG_FILE
        wait_for_enter
        return 1
    fi

    # Get selected project info
    local selected_index=$((project_choice - 1))
    local selected_project="${workspace_projects[selected_index]}"
    IFS=':' read -r current_display current_name current_start current_stop <<< "$selected_project"

    # Show edit screen
    clear
    print_header "Edit Project: $current_display"
    echo ""
    echo -e "${DIM}Current display name: ${BRIGHT_WHITE}${current_display}${NC}"
    echo -e "${DIM}Current startup cmd:  ${BRIGHT_YELLOW}${current_start}${NC}"
    echo -e "${DIM}Current shutdown cmd: ${BRIGHT_YELLOW}${current_stop}${NC}"
    echo ""

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

    # Show summary
    clear
    print_header "Confirm Project Changes"
    echo ""
    echo -e "  ${DIM}Display Name${NC}"
    echo -e "  ${BRIGHT_WHITE}${new_display}${NC}"
    echo ""
    echo -e "  ${DIM}Startup Command${NC}"
    echo -e "  ${BRIGHT_YELLOW}${new_startup}${NC}"
    echo ""
    echo -e "  ${DIM}Shutdown Command${NC}"
    echo -e "  ${BRIGHT_YELLOW}${new_shutdown}${NC}"
    echo ""

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

# Function to delete an empty workspace
# Parameters: workspace_file
# Returns: 0 if successful, 1 if error or cancelled
delete_workspace() {
    local workspace_file="$1"
    local display_name=$(format_workspace_display_name "$workspace_file")

    clear
    print_header "Delete Workspace"
    echo ""

    # Confirm deletion
    echo -e "${BRIGHT_RED}WARNING:${NC} You are about to delete workspace: ${BRIGHT_WHITE}${display_name}${NC}"
    echo ""
    echo -e "${DIM}Workspace file: ${workspace_file}${NC}"
    echo ""

    if prompt_yes_no_confirmation "Are you sure you want to delete this workspace?"; then
        # Remove from active config
        if remove_workspace_from_bulk_config "$workspace_file"; then
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
    clear
    print_header "Select Workspace to Manage"
    echo ""

    # Get active workspaces
    local active_workspaces=()
    local config_dir=$(get_config_directory)
    local workspaces_file="$config_dir/.workspaces.json"

    if [ ! -f "$workspaces_file" ] || ! get_active_workspaces active_workspaces || [ ${#active_workspaces[@]} -eq 0 ]; then
        print_error "No active workspaces found"
        echo ""
        print_info "Add a workspace first using 'a' from the settings menu"
        wait_for_enter
        return 1
    fi

    # Display workspaces with numbers
    local counter=1
    for workspace_file in "${active_workspaces[@]}"; do
        local display_name=$(format_workspace_display_name "$workspace_file")

        # Count projects
        local workspace_projects=()
        parse_workspace_projects "$workspace_file" workspace_projects
        local project_count=${#workspace_projects[@]}

        echo -e "  ${BRIGHT_CYAN}${counter}.${NC} ${BRIGHT_WHITE}${display_name}${NC} ${DIM}(${project_count} projects)${NC}"

        counter=$((counter + 1))
    done
    echo ""

    # Prompt for selection
    echo -ne "${BRIGHT_WHITE}Select workspace: ${BRIGHT_CYAN}"
    read -r workspace_choice
    echo -ne "${NC}" # Reset color

    # Handle empty input (go back)
    if [ -z "$workspace_choice" ]; then
        return 0
    fi

    # Validate choice is a number
    if ! [[ "$workspace_choice" =~ ^[0-9]+$ ]]; then
        print_error "Invalid choice. Please enter a number."
        wait_for_enter
        return 0
    fi

    # Validate choice is in range
    if [ "$workspace_choice" -lt 1 ] || [ "$workspace_choice" -gt "${#active_workspaces[@]}" ]; then
        print_error "Invalid choice. Please select a number between 1 and ${#active_workspaces[@]}."
        wait_for_enter
        return 0
    fi

    # Get selected workspace
    local selected_index=$((workspace_choice - 1))
    local selected_workspace="${active_workspaces[selected_index]}"

    # Open workspace management screen
    manage_workspace "$selected_workspace"

    return 0
}
