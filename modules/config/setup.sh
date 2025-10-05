#!/bin/bash

# ========================================
# Setup Module
# ========================================
# This module handles initial setup for new installations
# Usage: source modules/config/setup.sh

# Get the script directory to make paths relative to script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to check config and guide user through first-time setup
check_and_setup_config() {
    # Check if bulk config exists
    local config_dir
    if [ -d "config" ] && [ -f "startup.sh" ]; then
        config_dir="config"
    else
        config_dir="$HOME/.cache/fm-manager"
    fi

    local bulk_config_file="$config_dir/.bulk_project_config.json"

    # If no bulk config exists, this is first-time setup
    if [ ! -f "$bulk_config_file" ]; then
        print_header "WELCOME TO FM-MANAGER"
        echo ""
        print_info "This appears to be your first time running fm-manager."
        print_info "You'll need to create at least one workspace to get started."
        echo ""
        print_color "$BRIGHT_CYAN" "The manager will now start. Use Settings [s] to:"
        echo "  1. Create a new workspace"
        echo "  2. Add projects to your workspace"
        echo "  3. Activate the workspace"
        echo ""
        print_color "$BRIGHT_YELLOW" "Press Enter to continue..."
        read -r

        # Create empty bulk config to prevent this message from showing again
        mkdir -p "$config_dir"
        echo '{"activeConfig": [], "projectsPath": "", "availableConfigs": []}' > "$bulk_config_file"
    fi
}
