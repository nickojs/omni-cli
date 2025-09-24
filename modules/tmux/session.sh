#!/bin/bash

# ========================================
# Tmux Session Module
# ========================================
# This module handles tmux session management
# Usage: source modules/tmux/session.sh

# Tmux session name (use environment variable if set, otherwise default)
SESSION_NAME="${SESSION_NAME:-fm-session}"

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

    # Configure session for better scrolling and usability
    tmux set-option -t "$SESSION_NAME" mouse on
    tmux set-option -t "$SESSION_NAME" history-limit 10000
    tmux set-option -t "$SESSION_NAME" mode-keys vi
    
    print_success "Created tmux session: $SESSION_NAME with project menu"
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
