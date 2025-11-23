#!/bin/bash

# ========================================
# Setup Module
# ========================================
# This module handles initial setup for new installations
# Usage: source modules/config/setup.sh

# Get the script directory to make paths relative to script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to check if this is first-time setup (just checks, doesn't show UI)
is_first_time_setup() {
    local config_dir=$(get_config_directory)

    local workspaces_file="$config_dir/.workspaces.json"

    # Return 0 (true) if first time, 1 (false) if not
    if [ ! -f "$workspaces_file" ]; then
        return 0
    else
        return 1
    fi
}

# Function to initialize config for first-time setup
initialize_first_time_config() {
    local config_dir=$(get_config_directory)

    local workspaces_file="$config_dir/.workspaces.json"

    # Create empty workspaces config
    mkdir -p "$config_dir"
    echo '{"activeConfig": [], "projectsPath": "", "availableConfigs": [], "workspacePaths": {}}' > "$workspaces_file"
}

# Function to show first-time welcome screen (for use inside tmux)
show_first_time_welcome() {
    clear
    print_header "WELCOME TO FM-MANAGER"
    echo ""
    print_info "This appears to be your first time running fm-manager."
    print_info "You'll need to create at least one workspace to get started."
    echo ""
    print_color "$BRIGHT_CYAN" "Quick Start Guide:"
    echo "  ${BRIGHT_WHITE}1.${NC} Press ${BRIGHT_PURPLE}[s]${NC} to open Settings"
    echo "  ${BRIGHT_WHITE}2.${NC} Press ${BRIGHT_GREEN}[a]${NC} to Add a new workspace"
    echo "  ${BRIGHT_WHITE}3.${NC} Select the projects folder for your workspace"
    echo "  ${BRIGHT_WHITE}4.${NC} Add projects to your workspace"
    echo "  ${BRIGHT_WHITE}5.${NC} Start managing your projects!"
    echo ""
    print_color "$BRIGHT_YELLOW" "Press Enter to continue to the main menu..."
    read -r

    # Initialize config
    initialize_first_time_config
}
