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

# Function to parse command line arguments
parse_arguments() {
    AUTO_PROJECTS_DIR=""
    BACKUP_JSON=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            --tmux-menu)
                # This is handled in main(), just skip it here
                shift
                ;;
            --bkpJson)
                BACKUP_JSON=true
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            -*)
                echo "Unknown option: $1" >&2
                show_usage
                exit 1
                ;;
            *)
                # First non-option argument is the projects directory
                if [ -z "$AUTO_PROJECTS_DIR" ]; then
                    AUTO_PROJECTS_DIR="$1"
                fi
                shift
                ;;
        esac
    done

    # Export for use by other modules
    export AUTO_PROJECTS_DIR
    export BACKUP_JSON
}

# Function to show usage information
show_usage() {
    echo "Usage: fm-manager [OPTIONS] [PROJECTS_DIR]"
    echo ""
    echo "OPTIONS:"
    echo "  --bkpJson         Enable JSON backup creation (default: disabled)"
    echo "  --help, -h        Show this help message"
    echo ""
    echo "ARGUMENTS:"
    echo "  PROJECTS_DIR      Automatically use this directory for project scanning"
    echo "                    Examples: fm-manager ."
    echo "                             fm-manager ../projects"
    echo "                             fm-manager ~/code"
    echo ""
    echo "EXAMPLES:"
    echo "  fm-manager                    # Start normally"
    echo "  fm-manager .                  # Use current directory for projects"
    echo "  fm-manager --bkpJson .        # Use current dir + enable backups"
    echo "  fm-manager ~/projects         # Use ~/projects directory"
}

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
        else
            # Fallback to default if active config file doesn't exist
            JSON_CONFIG_FILE="$JSON_CONFIG_FOLDER/projects_output.json"
        fi
    else
        # Fallback to default if no bulk config file
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
    # Parse command line arguments first
    parse_arguments "$@"

    # Check if running with --tmux-menu flag (inside tmux session)
    if [ "$1" = "--tmux-menu" ]; then
        # Load config inside tmux session
        load_config
        show_project_menu_tmux
    else
        # Direct startup - go straight to tmux (no config loading here)
        check_tmux
        setup_tmux_session
        tmux attach-session -t "$SESSION_NAME"
    fi
}

main "$@"