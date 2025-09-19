#!/bin/bash

# ========================================
# Project Validation Module
# ========================================
# This module handles project configuration validation
# Usage: source modules/project/validation.sh

# Function to validate project configuration
validate_project_config() {
    local project_line="$1"
    
    IFS=':' read -r display_name folder_name startup_cmd <<< "$project_line"
    
    # Check if all fields are present
    if [ -z "$display_name" ] || [ -z "$folder_name" ] || [ -z "$startup_cmd" ]; then
        return 1
    fi
    
    # Check for valid characters (basic validation)
    if [[ "$display_name" =~ [^a-zA-Z0-9\ \-\_] ]]; then
        return 1
    fi
    
    return 0
}
