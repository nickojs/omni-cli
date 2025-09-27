#!/bin/bash

# ========================================
# Project Information Module
# ========================================
# This module handles project information retrieval
# Usage: source modules/project/info.sh

# Function to get project info by index
get_project_info() {
    local index="$1"
    
    if [ "$index" -ge 0 ] && [ "$index" -lt "${#projects[@]}" ]; then
        IFS=':' read -r display_name folder_name startup_cmd shutdown_cmd <<< "${projects[$index]}"
        echo "$display_name:$folder_name:$startup_cmd:$shutdown_cmd"
        return 0
    fi
    return 1
}

# Function to find project by name
find_project_by_name() {
    local search_name="$1"
    
    for i in "${!projects[@]}"; do
        IFS=':' read -r display_name folder_name startup_cmd shutdown_cmd <<< "${projects[i]}"
        if [[ "$display_name" == "$search_name" ]]; then
            echo "$i"
            return 0
        fi
    done
    
    return 1
}
