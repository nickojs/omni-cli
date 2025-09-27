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
    local shutdown_cmd="$2"
    local pane_id
    pane_id=$(get_project_pane "$display_name")

    if [[ -n "$pane_id" ]]; then
        # Execute shutdown command if provided
        if [[ -n "$shutdown_cmd" ]] && [[ "$shutdown_cmd" != "null" ]] && [[ "$shutdown_cmd" != "echo 'No shutdown command configured'" ]]; then
            tmux send-keys -t "$pane_id" C-c 2>/dev/null  # Send Ctrl+C to interrupt current process
            sleep 0.5

            # Send shutdown command and wait for it to complete
            tmux send-keys -t "$pane_id" "$shutdown_cmd" Enter 2>/dev/null

            # Monitor command completion by checking if shell prompt is back
            while true; do
                # Check if there are any running processes in the pane
                local pane_pid
                pane_pid=$(tmux list-panes -t "$pane_id" -F "#{pane_pid}" 2>/dev/null)

                if [[ -n "$pane_pid" ]]; then
                    # Check if any child processes are still running
                    local child_procs
                    child_procs=$(pgrep -P "$pane_pid" 2>/dev/null | wc -l)

                    # If no child processes, the shutdown command has completed
                    if [[ "$child_procs" -eq 0 ]]; then
                        break
                    fi
                fi

                sleep 0.5
            done

            # Additional 2-second buffer after shutdown command completes
            sleep 2
        fi

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
    # Get pane info with titles to match against projects
    local pane_info
    mapfile -t pane_info < <(tmux list-panes -t "$SESSION_NAME" -F "#{pane_id}:#{pane_title}" 2>/dev/null | grep -v "^%0:")

    for info in "${pane_info[@]}"; do
        IFS=':' read -r pane_id pane_title <<< "$info"

        # Find the shutdown command for this project
        local shutdown_cmd=""
        for i in "${!projects[@]}"; do
            IFS=':' read -r display_name folder_name startup_cmd project_shutdown_cmd <<< "${projects[i]}"
            if [[ "$display_name" == "$pane_title" ]]; then
                shutdown_cmd="$project_shutdown_cmd"
                break
            fi
        done

        # Execute shutdown command if provided
        if [[ -n "$shutdown_cmd" ]] && [[ "$shutdown_cmd" != "null" ]] && [[ "$shutdown_cmd" != "echo 'No shutdown command configured'" ]]; then
            tmux send-keys -t "$pane_id" C-c 2>/dev/null  # Send Ctrl+C to interrupt current process
            sleep 0.5

            # Send shutdown command and wait for it to complete
            tmux send-keys -t "$pane_id" "$shutdown_cmd" Enter 2>/dev/null

            # Monitor command completion by checking if shell prompt is back
            while true; do
                # Check if there are any running processes in the pane
                local pane_pid_check
                pane_pid_check=$(tmux list-panes -t "$pane_id" -F "#{pane_pid}" 2>/dev/null)

                if [[ -n "$pane_pid_check" ]]; then
                    # Check if any child processes are still running
                    local child_procs
                    child_procs=$(pgrep -P "$pane_pid_check" 2>/dev/null | wc -l)

                    # If no child processes, the shutdown command has completed
                    if [[ "$child_procs" -eq 0 ]]; then
                        break
                    fi
                fi

                sleep 0.5
            done

            # Additional 2-second buffer after shutdown command completes
            sleep 2
        fi

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
