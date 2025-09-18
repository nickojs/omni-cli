#!/bin/bash

# Import all modules
source "$(dirname "$0")/styles/index.sh"
source "$(dirname "$0")/modules/index.sh"

# Set JSON_CONFIG_FILE as environment variable immediately
if [ -f "$(dirname "$0")/.env" ]; then
    JSON_CONFIG_FILE=$(grep "^JSON_CONFIG_FILE=" "$(dirname "$0")/.env" | cut -d= -f2)
    SESSION_NAME=$(grep "^SESSION_NAME=" "$(dirname "$0")/.env" | cut -d= -f2)
    SCRIPT_BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
    FULL_PATH="$SCRIPT_BASE_DIR/$JSON_CONFIG_FILE"
    export JSON_CONFIG_FILE="$FULL_PATH"
    export SESSION_NAME="$SESSION_NAME"
fi

main() {
    # Check if running with --tmux-menu flag (inside tmux session)  
    if [ "$1" = "--tmux-menu" ]; then
        load_config
        show_project_menu_tmux
    else
        # Startup sequence
        print_header "INITIALIZING PROJECT MANAGER"
        
        check_and_setup_config
        show_loading "Loading configuration" 1
        load_config
        
        show_loading "Checking tmux availability" 1
        check_tmux
        
        setup_tmux_session
        
        # Attach to the session
        show_loading "Attaching to session" 1
        tmux attach-session -t "$SESSION_NAME"
    fi
}

main "$@"