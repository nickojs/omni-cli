#!/bin/bash

# Detect if running from installed location or development directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Determine base directory
if [[ "$SCRIPT_DIR" == *"/usr/bin"* ]]; then
    BASE_DIR="/usr/share/fm-manager"
    IS_INSTALLED=true
else
    BASE_DIR="$(dirname "${BASH_SOURCE[0]}")"
    IS_INSTALLED=false
fi

# Function to set up configuration paths
setup_config_paths() {
    # Load .env file if it exists
    if [ -f "$BASE_DIR/.env" ]; then
        source "$BASE_DIR/.env"
    fi
    
    # Set default values if not in .env
    SESSION_NAME="${SESSION_NAME:-fm-manager}"
    
    # Set JSON_CONFIG_FILE based on installation type
    if [ "$IS_INSTALLED" = true ]; then
        # Installed: use user cache directory
        JSON_CONFIG_FOLDER="$HOME/.cache/fm-manager"
        if ! mkdir -p "$JSON_CONFIG_FOLDER" 2>/dev/null; then
            echo "Error: Failed to create cache directory: $JSON_CONFIG_FOLDER" >&2
            echo "Please check permissions or try running: mkdir -p $JSON_CONFIG_FOLDER" >&2
            exit 1
        fi
        JSON_CONFIG_FILE="$JSON_CONFIG_FOLDER/projects_output.json"
    else
        # Development: use relative to script directory
        JSON_CONFIG_FOLDER="$BASE_DIR/config"
        if ! mkdir -p "$JSON_CONFIG_FOLDER" 2>/dev/null; then
            echo "Error: Failed to create config directory: $JSON_CONFIG_FOLDER" >&2
            exit 1
        fi
        JSON_CONFIG_FILE="$JSON_CONFIG_FOLDER/projects_output.json"
    fi
    
    # Export for use by other modules
    export BASE_DIR
    export SESSION_NAME
    export JSON_CONFIG_FOLDER
    export JSON_CONFIG_FILE
}

# Import all modules after setting up paths
setup_config_paths
source "$BASE_DIR/styles/index.sh"
source "$BASE_DIR/modules/index.sh"
source "$BASE_DIR/docs/index.sh"

main() {
    # Check if running with --tmux-menu flag (inside tmux session)
    if [ "$1" = "--tmux-menu" ]; then
        load_config
        show_project_menu_tmux
    else
        # Clear terminal before starting session
        clear
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