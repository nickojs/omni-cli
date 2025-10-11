#!/bin/bash

# ========================================
# Configuration Loader Module
# ========================================
# This module handles the main configuration loading logic
# Usage: source modules/config/loader.sh

# Load the project configuration (silent - no user prompts)
load_config() {
    # Try to load projects, but don't show errors
    if ! load_projects_from_json 2>/dev/null; then
        # Set empty projects array to allow menu to load
        projects=()
        project_workspaces=()
    fi

    # Return success regardless - menu will handle empty state
    return 0
}
