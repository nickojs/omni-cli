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
            mark_project_stopping "$display_name"
            with_workspace_context "$workspace_file" kill_project "$display_name" "$shutdown_command"
        fi
    fi
}

# Function to handle restart command with global project array
handle_restart_command() {
    local restart_choice="$1"

    if [ "$restart_choice" -ge 1 ] && [ "$restart_choice" -le "${#projects[@]}" ]; then
        local project_index=$((restart_choice - 1))
        IFS=':' read -r display_name folder_name startup_command shutdown_command <<< "${projects[$project_index]}"

        if is_project_running "$display_name"; then
            restart_project "$display_name" "$startup_command" "$shutdown_command"
        fi
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

    kill_all_projects
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
