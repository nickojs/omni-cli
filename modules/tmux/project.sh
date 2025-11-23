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

    # Count existing project panes (excluding main menu pane %0)
    local project_pane_count
    project_pane_count=$(tmux list-panes -t "$SESSION_NAME" -F "#{pane_id}" 2>/dev/null | grep -v "^%0$" | wc -l)

    local new_pane_id
    if [[ "$project_pane_count" -eq 0 ]]; then
        # First project: create below the main menu (vertical split)
        new_pane_id=$(tmux split-window -v -t "$SESSION_NAME:0.0" -c "$PWD/$folder_name" -P -F "#{pane_id}")
    else
        # Subsequent projects: split horizontally from the last project pane
        local last_project_pane
        last_project_pane=$(tmux list-panes -t "$SESSION_NAME" -F "#{pane_id}" 2>/dev/null | grep -v "^%0$" | tail -n1)
        new_pane_id=$(tmux split-window -h -t "$last_project_pane" -c "$PWD/$folder_name" -P -F "#{pane_id}")
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

# Function to run a custom command in tmux pane that auto-closes when done
start_custom_command_in_tmux() {
    local display_name="$1"
    local folder_name="$2"
    local command="$3"

    # Check if folder exists
    if [ ! -d "$folder_name" ]; then
        print_error "Project folder '$folder_name' not found"
        return 1
    fi

    print_info "Running $display_name in new tmux pane..."

    # Escape single quotes in command for bash -c
    local escaped_command="${command//\'/\'\\\'\'}"

    # Wrap command to run and auto-exit
    local wrapped_cmd="bash -c 'cd \"$PWD/$folder_name\" && $escaped_command; echo; echo \"Command completed. Pane closing...\"; sleep 1'"

    # Count existing project panes (excluding main menu pane %0)
    local project_pane_count
    project_pane_count=$(tmux list-panes -t "$SESSION_NAME" -F "#{pane_id}" 2>/dev/null | grep -v "^%0$" | wc -l)

    local new_pane_id
    if [[ "$project_pane_count" -eq 0 ]]; then
        # First project: create below the main menu (vertical split) with command
        new_pane_id=$(tmux split-window -v -t "$SESSION_NAME:0.0" -P -F "#{pane_id}" "$wrapped_cmd")
    else
        # Subsequent projects: split horizontally from the last project pane
        local last_project_pane
        last_project_pane=$(tmux list-panes -t "$SESSION_NAME" -F "#{pane_id}" 2>/dev/null | grep -v "^%0$" | tail -n1)
        new_pane_id=$(tmux split-window -h -t "$last_project_pane" -P -F "#{pane_id}" "$wrapped_cmd")
    fi

    # Set pane to auto-close when command exits
    tmux set-option -p -t "$new_pane_id" remain-on-exit off

    # Set pane title
    tmux select-pane -t "$new_pane_id" -T "$display_name"

    # Apply main-horizontal layout
    tmux select-layout -t "$SESSION_NAME" main-horizontal

    # Switch back to the main pane (menu pane)
    tmux select-pane -t "$SESSION_NAME:0.0"

    print_success "$display_name started successfully in tmux pane ($new_pane_id)"
    return 0
}
