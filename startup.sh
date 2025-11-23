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
    
    # Set JSON_CONFIG_FOLDER based on installation type
    if [ "$IS_INSTALLED" = true ]; then
        # Installed: use user cache directory
        JSON_CONFIG_FOLDER="$HOME/.cache/fm-manager"
        if ! mkdir -p "$JSON_CONFIG_FOLDER" 2>/dev/null; then
            echo "Error: Failed to create cache directory: $JSON_CONFIG_FOLDER" >&2
            echo "Please check permissions or try running: mkdir -p $JSON_CONFIG_FOLDER" >&2
            exit 1
        fi
    else
        # Development: use relative to script directory
        JSON_CONFIG_FOLDER="$BASE_DIR/config"
        if ! mkdir -p "$JSON_CONFIG_FOLDER" 2>/dev/null; then
            echo "Error: Failed to create config directory: $JSON_CONFIG_FOLDER" >&2
            exit 1
        fi
    fi

    # Determine active configuration from .workspaces.json or fallback to default
    local workspaces_file="$JSON_CONFIG_FOLDER/.workspaces.json"
    if [ -f "$workspaces_file" ] && command -v jq >/dev/null 2>&1; then
        # Get the first active workspace from the activeConfig array
        local active_config=$(jq -r '.activeConfig[0] // empty' "$workspaces_file" 2>/dev/null)
        if [ -n "$active_config" ] && [ -f "$active_config" ]; then
            JSON_CONFIG_FILE="$active_config"
        fi
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

main() {
    # Check if already inside a tmux session
    if [ -n "$TMUX" ]; then
        # Already in tmux - load config and show menu
        load_config
        show_project_menu_tmux
    else
        # Not in tmux - create/attach to session
        check_tmux
        setup_tmux_session
        tmux attach-session -t "$SESSION_NAME"
    fi
}

main "$@"