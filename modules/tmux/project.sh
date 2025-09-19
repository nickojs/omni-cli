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
    
    # Create new pane BELOW (split horizontally with -v instead of -h)
    local new_pane_id
    new_pane_id=$(tmux split-window -v -t "$SESSION_NAME" -c "$PWD/$folder_name" -P -F "#{pane_id}")
    
    # Set pane title FIRST (important!)
    tmux select-pane -t "$new_pane_id" -T "$display_name"
    
    # Send the startup command to the new pane
    tmux send-keys -t "$new_pane_id" "$startup_command" Enter
    
    # Switch back to the main pane (menu pane)
    tmux select-pane -t "$SESSION_NAME:0.0"
    
    print_success "$display_name started successfully in tmux pane ($new_pane_id)"
    return 0
}
