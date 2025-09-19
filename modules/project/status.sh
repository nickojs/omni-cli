#!/bin/bash

# ========================================
# Project Status Module
# ========================================
# This module handles project status checking and counting
# Usage: source modules/project/status.sh

# Function to validate project folder exists
validate_project_folder() {
    local folder_name="$1"
    
    if [ -d "$folder_name" ]; then
        return 0
    else
        return 1
    fi
}

# Function to count running projects
count_running_projects() {
    local count=0
    
    for project in "${projects[@]}"; do
        IFS=':' read -r display_name folder_name startup_cmd <<< "$project"
        if is_project_running "$display_name"; then
            ((count++))
        fi
    done
    
    echo "$count"
}
