#!/bin/bash

# ========================================
# JSON Parser Module
# ========================================
# This module handles JSON parsing functionality
# Usage: source modules/config/json.sh

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

# Function to write project configurations to JSON file
# Parameters: project_configs array (passed by reference), projects_dir
write_json_config() {
    local -n configs_ref=$1
    local projects_dir=$2
    local json_file="$JSON_CONFIG_FILE"

    print_header "GENERATING CONFIGURATION"

    # Start JSON array
    echo "[" > "$json_file"

    for i in "${!configs_ref[@]}"; do
        local config="${configs_ref[i]}"
        IFS=':' read -r display_name folder_name startup_cmd <<< "$config"

        # Add comma for all but the last item
        local comma=""
        if [ $((i + 1)) -lt ${#configs_ref[@]} ]; then
            comma=","
        fi

        # Write JSON object
        cat >> "$json_file" << EOF
    {
        "displayName": "$display_name",
        "projectName": "$folder_name",
        "relativePath": "${projects_dir%/}/$folder_name",
        "startupCmd": "$startup_cmd"
    }$comma
EOF
    done

    # Close JSON array
    echo "]" >> "$json_file"

    print_success "Configuration saved to: $json_file"

    # Show preview
    echo ""
    print_color "$BRIGHT_YELLOW" "Generated configuration preview:"
    echo ""
    cat "$json_file"
}
