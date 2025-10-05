#!/bin/bash

# ========================================
# Configuration Loader Module
# ========================================
# This module handles the main configuration loading logic
# Usage: source modules/config/loader.sh

# Load the project configuration
load_config() {
    if ! load_projects_from_json; then
        print_error "Could not load configuration"
        echo ""
        print_info "Please use Settings [s] to create and activate a workspace."
        echo ""
        print_color "$BRIGHT_YELLOW" "Press Enter to continue to main menu..."
        read -r
        # Set empty projects array to allow menu to load
        projects=()
        project_workspaces=()
    fi

    # Verify we have projects
    if [ ${#projects[@]} -eq 0 ]; then
        print_warning "No active workspaces with projects found."
        echo ""
        print_info "Use Settings [s] to:"
        echo "  1. Create a workspace"
        echo "  2. Add projects to the workspace"
        echo "  3. Activate the workspace"
        echo ""
        print_color "$BRIGHT_YELLOW" "Press Enter to continue to main menu..."
        read -r
    fi
}
