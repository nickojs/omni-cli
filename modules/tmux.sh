#!/bin/bash

# ========================================
# Tmux Management Module
# ========================================
# This module handles all tmux-related operations
# Usage: source modules/tmux.sh

# Tmux session name (use environment variable if set, otherwise default)
SESSION_NAME="${SESSION_NAME:-fm-session}"

# Function to check if tmux is available
check_tmux() {
    if ! command -v tmux &> /dev/null; then
        print_error "tmux is not installed. Please install tmux to use this script."
        exit 1
    fi
}

# Function to create or attach to tmux session
setup_tmux_session() {
    # Check if session already exists
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        print_warning "Tmux session '$SESSION_NAME' already exists."
        print_color "$BRIGHT_YELLOW" "Do you want to attach to existing session? ${BOLD}(y/n)${NC}: "
        read -r attach_choice
        if [[ $attach_choice =~ ^[Yy]$ ]]; then
            show_loading "Attaching to existing session" 1
            tmux attach-session -t "$SESSION_NAME"
            exit 0
        else
            show_loading "Killing existing session" 1
            tmux kill-session -t "$SESSION_NAME"
        fi
    fi
    
    # Create new session (detached) and start the menu in it
    show_loading "Creating tmux session" 1
    tmux new-session -d -s "$SESSION_NAME" "$0 --tmux-menu"
    
    print_success "Created tmux session: $SESSION_NAME with project menu"
}

# Function to get pane info for a specific project
get_project_pane() {
    local display_name="$1"
    
    # Get all panes with their titles
    tmux list-panes -t "$SESSION_NAME" -F "#{pane_id}:#{pane_title}" 2>/dev/null | while IFS=':' read -r pane_id pane_title; do
        if [[ "$pane_title" == "$display_name" ]]; then
            echo "$pane_id"
            return 0
        fi
    done
    
    return 1
}

# Function to check if project is running
is_project_running() {
    local display_name="$1"
    local pane_id
    pane_id=$(get_project_pane "$display_name")
    [[ -n "$pane_id" ]]
}

# Function to kill a specific project pane
kill_project() {
    local display_name="$1"
    local pane_id
    pane_id=$(get_project_pane "$display_name")
    
    if [[ -n "$pane_id" ]]; then
        tmux kill-pane -t "$pane_id" 2>/dev/null
        return 0
    fi
    return 1
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

# Function to list all project panes
list_project_panes() {
    tmux list-panes -t "$SESSION_NAME" -F "#{pane_id}:#{pane_title}" 2>/dev/null | grep -v "^%0:"
}

# Function to kill all project panes (except main menu)
kill_all_projects() {
    local pane_ids
    mapfile -t pane_ids < <(tmux list-panes -t "$SESSION_NAME" -F "#{pane_id}" 2>/dev/null | grep -v "^%0$")
    
    for pane_id in "${pane_ids[@]}"; do
        tmux kill-pane -t "$pane_id" 2>/dev/null
    done
}

# Function to attach to existing session
attach_session() {
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        tmux attach-session -t "$SESSION_NAME"
        return 0
    else
        return 1
    fi
}

# Function to check session status
session_status() {
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        local pane_count
        pane_count=$(tmux list-panes -t "$SESSION_NAME" 2>/dev/null | wc -l)
        echo "Session '$SESSION_NAME' is running with $pane_count panes"
        return 0
    else
        echo "Session '$SESSION_NAME' is not running"
        return 1
    fi
}
