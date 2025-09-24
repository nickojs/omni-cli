#!/bin/bash

# ========================================
# Tmux Pane Module
# ========================================
# This module handles tmux pane management
# Usage: source modules/tmux/pane.sh

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

# Function to kill a specific project pane
kill_project() {
    local display_name="$1"
    local pane_id
    pane_id=$(get_project_pane "$display_name")

    if [[ -n "$pane_id" ]]; then
        # Get the shell PID running in the pane
        local pane_pid
        pane_pid=$(tmux list-panes -t "$pane_id" -F "#{pane_pid}" 2>/dev/null)

        if [[ -n "$pane_pid" ]]; then
            # Kill the entire process group (graceful first, then force)
            kill -TERM -"$pane_pid" 2>/dev/null
            sleep 0.5
            kill -KILL -"$pane_pid" 2>/dev/null
        fi

        # Kill the pane
        tmux kill-pane -t "$pane_id" 2>/dev/null
        return 0
    fi
    return 1
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
        # Get the shell PID running in the pane
        local pane_pid
        pane_pid=$(tmux list-panes -t "$pane_id" -F "#{pane_pid}" 2>/dev/null)

        if [[ -n "$pane_pid" ]]; then
            # Kill the entire process group (graceful first, then force)
            kill -TERM -"$pane_pid" 2>/dev/null
            sleep 0.2
            kill -KILL -"$pane_pid" 2>/dev/null
        fi

        # Kill the pane
        tmux kill-pane -t "$pane_id" 2>/dev/null
    done
}
