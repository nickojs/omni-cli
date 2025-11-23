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
        # Session exists, just return (will attach in main)
        return 0
    fi

    # Create new session (detached) and start the menu in it
    tmux new-session -d -s "$SESSION_NAME" "$0"

    # Configure session for better scrolling and usability
    tmux set-option -t "$SESSION_NAME" mouse on
    tmux set-option -t "$SESSION_NAME" history-limit 10000
    tmux set-option -t "$SESSION_NAME" mode-keys vi
}
