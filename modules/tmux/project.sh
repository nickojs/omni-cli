#!/bin/bash

# ========================================
# Tmux Project Module
# ========================================
# This module handles project-specific tmux operations
# Usage: source modules/tmux/project.sh

# Function to check if project is running
is_project_running() {
    local display_name="$1"
    local pane_id
    pane_id=$(get_project_pane "$display_name")
    [[ -n "$pane_id" ]]
}

# Function to get the first project pane (used as reference for splitting)
get_first_project_pane() {
    # Get the first non-main-menu pane
    tmux list-panes -t "$SESSION_NAME" -F "#{pane_id}:#{pane_title}" 2>/dev/null | grep -v "^%0:" | head -n1 | cut -d: -f1
}

# Function to start project in new tmux pane
start_project_in_tmux() {
    local display_name="$1"
    local folder_name="$2"
    local startup_command="$3"

    # Check if folder exists
    if [ ! -d "$folder_name" ]; then
        print_error "Project folder '$folder_name' not found"
        return 1
    fi

    print_info "Starting $display_name in new tmux pane..."

    # Check if this is the first project
    local first_project_pane
    first_project_pane=$(get_first_project_pane)

    local new_pane_id
    if [[ -z "$first_project_pane" ]]; then
        # First project: create below the main menu (vertical split)
        new_pane_id=$(tmux split-window -v -t "$SESSION_NAME:0.0" -c "$PWD/$folder_name" -P -F "#{pane_id}")
    else
        # Subsequent projects: split horizontally with the first project
        new_pane_id=$(tmux split-window -h -t "$first_project_pane" -c "$PWD/$folder_name" -P -F "#{pane_id}")
    fi

    # Set pane title FIRST (important!)
    tmux select-pane -t "$new_pane_id" -T "$display_name"

    # Send the startup command to the new pane
    tmux send-keys -t "$new_pane_id" "$startup_command" Enter

    # Apply main-horizontal layout to keep manager on top and projects evenly distributed below
    tmux select-layout -t "$SESSION_NAME" main-horizontal

    # Switch back to the main pane (menu pane)
    tmux select-pane -t "$SESSION_NAME:0.0"

    print_success "$display_name started successfully in tmux pane ($new_pane_id)"
    return 0
}
