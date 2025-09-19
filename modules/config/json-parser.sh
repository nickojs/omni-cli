#!/bin/bash

# ========================================
# JSON Parser Module
# ========================================
# This module handles JSON parsing functionality
# Usage: source modules/config/json-parser.sh

# Global projects array
declare -g -a projects=()

# Function to load projects from JSON config
load_projects_from_json() {
    local json_file="$JSON_CONFIG_FILE"
    
    if [ ! -f "$json_file" ]; then
        return 1
    fi
    
    # Parse JSON and create the projects array
    projects=()
    
    # Read each project object from JSON
    while IFS= read -r line; do
        # Skip lines that don't contain project objects
        if [[ ! "$line" =~ \"displayName\" ]]; then
            continue
        fi
        
        # Extract values using basic string manipulation
        local display_name=$(echo "$line" | grep -o '"displayName": *"[^"]*"' | sed 's/"displayName": *"//' | sed 's/".*//')
        local relative_path=$(echo "$line" | grep -o '"relativePath": *"[^"]*"' | sed 's/"relativePath": *"//' | sed 's/".*//')
        local startup_cmd=$(echo "$line" | grep -o '"startupCmd": *"[^"]*"' | sed 's/"startupCmd": *"//' | sed 's/".*//')
        
        # Add to projects array in the original format (using relativePath as folder_name)
        if [ -n "$display_name" ] && [ -n "$relative_path" ] && [ -n "$startup_cmd" ]; then
            projects+=("$display_name:$relative_path:$startup_cmd")
        fi
    done < <(cat "$json_file" | tr -d '\n' | sed 's/},/},\n/g' | grep -o '{[^}]*}')
    
    return 0
}

# Function to reload configuration (used after wizard re-run)
reload_config() {
    if load_projects_from_json; then
        return 0
    else
        return 1
    fi
}
