#!/bin/bash

# ========================================
# Menu Actions Module
# ========================================
# This module handles menu action implementations
# Usage: source modules/menu/actions.sh

# Helper function to temporarily switch workspace context for operations
with_workspace_context() {
    local workspace_file="$1"
    local callback_function="$2"
    shift 2  # Remove workspace_file and callback_function, rest are callback args

    # Save current context
    local original_json_config="$JSON_CONFIG_FILE"

    # Switch to target workspace
    export JSON_CONFIG_FILE="$workspace_file"

    # Execute callback with remaining arguments
    "$callback_function" "$@"
    local result=$?

    # Restore original context
    export JSON_CONFIG_FILE="$original_json_config"

    return $result
}

# Function to handle quit command
handle_quit_command() {
    show_loading "bye bye!" 1
    tmux kill-session
    exit 0
}


# Function to handle kill command with global project array
handle_kill_command() {
    local kill_choice="$1"

    if [ "$kill_choice" -ge 1 ] && [ "$kill_choice" -le "${#projects[@]}" ]; then
        local project_index=$((kill_choice - 1))
        IFS=':' read -r display_name folder_name startup_command shutdown_command <<< "${projects[$project_index]}"
        local workspace_file="${project_workspaces[$project_index]}"

        if is_project_running "$display_name"; then
            show_loading "Killing $display_name" 1

            # Kill project with workspace context (shutdown command execution needs proper context)
            if with_workspace_context "$workspace_file" kill_project "$display_name" "$shutdown_command"; then
                print_success "$display_name stopped successfully"
            else
                print_error "Failed to stop $display_name"
            fi
        else
            print_warning "$display_name is not running"
        fi
        wait_for_enter
    else
        print_error "Invalid kill command. Use k1-k${#projects[@]}"
        sleep 2
    fi
}

# Function to handle start command with global project array
handle_start_command() {
    local choice="$1"

    if [ "$choice" -ge 1 ] && [ "$choice" -le "${#projects[@]}" ]; then
        local project_index=$((choice - 1))
        IFS=':' read -r display_name folder_name startup_command shutdown_command <<< "${projects[$project_index]}"
        local workspace_file="${project_workspaces[$project_index]}"

        # Check if project is already running
        if is_project_running "$display_name"; then
            echo ""
            print_warning "$display_name is already running!"
            print_info "Use 'k$choice' to kill it first, then start again."
            wait_for_enter
            return
        fi

        print_separator
        echo -e "${BRIGHT_WHITE}Selected project:${NC} ${BRIGHT_GREEN}$display_name${NC}"
        echo -e "${BRIGHT_WHITE}Project folder:${NC} ${BRIGHT_BLUE}$folder_name${NC}"
        echo -e "${BRIGHT_WHITE}Startup command:${NC} ${BRIGHT_YELLOW}$startup_command${NC}"
        echo -e "${BRIGHT_WHITE}Workspace:${NC} ${BRIGHT_CYAN}$(basename "$workspace_file" .json)${NC}"
        print_separator

        # Start project with workspace context
        with_workspace_context "$workspace_file" start_project_in_tmux "$display_name" "$folder_name" "$startup_command"

        echo ""
        wait_for_enter "Press Enter to return to menu..."
    else
        print_error "Please enter a number between 1 and ${#projects[@]}"
        wait_for_enter
    fi
}


# Function to handle custom config command
handle_custom_config_command() {
    clear
    print_header "Run Custom Command"
    echo ""

    # Get config directory
    local config_dir=$(get_config_directory)
    local workspaces_file="$config_dir/.workspaces.json"

    # Build list of projects with custom commands
    local projects_with_cmds=()
    local project_folders=()
    local project_workspaces=()
    local custom_commands_data=()

    # Get only active workspaces
    local workspace_files=()
    if [ -f "$workspaces_file" ] && command -v jq >/dev/null 2>&1; then
        while IFS= read -r active_workspace; do
            local full_workspace_path="$config_dir/$active_workspace"
            if [ -f "$full_workspace_path" ]; then
                workspace_files+=("$full_workspace_path")
            fi
        done < <(jq -r '.activeConfig[]? // empty' "$workspaces_file" 2>/dev/null)
    fi

    # Collect all projects with custom commands
    for workspace_file in "${workspace_files[@]}"; do
        while IFS= read -r line; do
            if [ -n "$line" ]; then
                IFS=':' read -r proj_display proj_folder custom_cmds_json <<< "$line"
                projects_with_cmds+=("$proj_display")
                project_folders+=("$proj_folder")
                project_workspaces+=("$workspace_file")
                custom_commands_data+=("$custom_cmds_json")
            fi
        done < <(jq -r '.[] | select(.customCommands and (.customCommands | length) > 0) | "\(.displayName):\(.relativePath):\(.customCommands | @json)"' "$workspace_file" 2>/dev/null)
    done

    # Check if any projects have custom commands
    if [ ${#projects_with_cmds[@]} -eq 0 ]; then
        echo -e "${DIM}No custom commands configured yet${NC}"
        echo ""
        echo -e "${DIM}Add custom commands in ${BRIGHT_PURPLE}s${NC} ${DIM}settings menu${NC}"
        echo ""
        wait_for_enter
        return
    fi

    # Display projects
    echo -e "${BRIGHT_WHITE}Projects with custom commands:${NC}"
    echo ""
    for i in "${!projects_with_cmds[@]}"; do
        local display_num=$((i + 1))
        echo -e "  ${BRIGHT_CYAN}${display_num}${NC} ${BRIGHT_WHITE}${projects_with_cmds[i]}${NC} ${BRIGHT_PURPLE}⚙${NC}"
    done
    echo ""

    # Prompt for project selection
    echo -e "${BRIGHT_WHITE}Select project ${DIM}(ESC to cancel):${NC}"
    echo -ne "${BRIGHT_CYAN}>${NC} "
    read -n 1 project_choice
    echo ""

    # Handle ESC or empty
    if [ -z "$project_choice" ] || [ "$project_choice" = $'\e' ]; then
        return
    fi

    # Validate project choice
    if ! [[ "$project_choice" =~ ^[0-9]+$ ]] || [ "$project_choice" -lt 1 ] || [ "$project_choice" -gt "${#projects_with_cmds[@]}" ]; then
        echo ""
        print_error "Invalid selection"
        wait_for_enter
        return
    fi

    local selected_project_idx=$((project_choice - 1))
    local selected_project="${projects_with_cmds[selected_project_idx]}"
    local selected_folder="${project_folders[selected_project_idx]}"
    local selected_workspace="${project_workspaces[selected_project_idx]}"
    local selected_cmds="${custom_commands_data[selected_project_idx]}"

    # Parse commands for selected project
    local cmd_names=()
    local cmd_values=()
    while IFS= read -r cmd_line; do
        if [ -n "$cmd_line" ]; then
            IFS=':' read -r cmd_name cmd_value <<< "$cmd_line"
            cmd_names+=("$cmd_name")
            cmd_values+=("$cmd_value")
        fi
    done < <(echo "$selected_cmds" | jq -r 'to_entries[] | "\(.key):\(.value)"' 2>/dev/null)

    # Display commands for selected project
    echo ""
    echo -e "${BRIGHT_WHITE}Custom commands for ${selected_project}:${NC}"
    echo ""
    for i in "${!cmd_names[@]}"; do
        local display_num=$((i + 1))
        echo -e "  ${BRIGHT_CYAN}${display_num}${NC} ${BRIGHT_WHITE}${cmd_names[i]}${NC} ${DIM}${cmd_values[i]}${NC}"
    done
    echo ""

    # Prompt for command selection
    echo -e "${BRIGHT_WHITE}Select command ${DIM}(ESC to cancel):${NC}"
    echo -ne "${BRIGHT_CYAN}>${NC} "
    read -n 1 cmd_choice
    echo ""

    # Handle ESC or empty
    if [ -z "$cmd_choice" ] || [ "$cmd_choice" = $'\e' ]; then
        return
    fi

    # Validate command choice
    if ! [[ "$cmd_choice" =~ ^[0-9]+$ ]] || [ "$cmd_choice" -lt 1 ] || [ "$cmd_choice" -gt "${#cmd_names[@]}" ]; then
        echo ""
        print_error "Invalid selection"
        wait_for_enter
        return
    fi

    local selected_cmd_idx=$((cmd_choice - 1))
    local selected_cmd_name="${cmd_names[selected_cmd_idx]}"
    local selected_cmd_value="${cmd_values[selected_cmd_idx]}"

    # Execute the command in a new tmux pane
    echo ""
    echo -e "${BRIGHT_WHITE}Running:${NC} ${BRIGHT_CYAN}${selected_cmd_name}${NC}"
    echo -e "${BRIGHT_WHITE}Command:${NC} ${DIM}${selected_cmd_value}${NC}"
    echo ""

    # Create tmux pane with the custom command (auto-closes when done)
    local pane_name="${selected_project}-${selected_cmd_name}"
    with_workspace_context "$selected_workspace" start_custom_command_in_tmux "$pane_name" "$selected_folder" "$selected_cmd_value"

    wait_for_enter
}

# Function to handle settings command
handle_settings_command() {
    show_settings_menu
    # Reload configuration after returning from settings
    # This ensures the main menu reflects any changes made in settings
    reload_config
}

# Function to handle kill all command
handle_kill_all_command() {
    # Check if there are any running projects
    local running_projects
    running_projects=$(list_project_panes)

    if [[ -z "$running_projects" ]]; then
        print_warning "No projects are currently running"
        wait_for_enter
        return
    fi

    show_loading "Killing all running projects" 2
    kill_all_projects
    print_success "All projects stopped successfully"
    wait_for_enter
}

# Function to handle help command
handle_help_command() {
    show_menu_help
}

# Function to handle custom command (open terminal in project folder)
handle_custom_command() {
    local choice="$1"

    if [ "$choice" -ge 1 ] && [ "$choice" -le "${#projects[@]}" ]; then
        local project_index=$((choice - 1))
        IFS=':' read -r display_name folder_name startup_command shutdown_command <<< "${projects[$project_index]}"

        # Check if folder exists
        if [ ! -d "$folder_name" ]; then
            print_error "Project folder '$folder_name' not found"
            wait_for_enter
            return 1
        fi

        print_info "Opening terminal for $display_name in $folder_name"

        # Open new kgx terminal window in the project folder
        kgx --working-directory="$folder_name" &

        print_success "Terminal opened for $display_name"
        sleep 1
    else
        print_error "Please enter a number between 1 and ${#projects[@]}"
        wait_for_enter
    fi
}
