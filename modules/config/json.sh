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
    
    # Read each project object from JSON - use safer approach
    local json_content
    json_content=$(cat "$json_file" 2>/dev/null)
    if [ $? -ne 0 ] || [ -z "$json_content" ]; then
        return 1
    fi

    # Remove newlines and split on project boundaries
    local flat_json
    flat_json=$(echo "$json_content" | tr -d '\n\r' | sed 's/},/},\n/g')

    # Extract JSON objects - use more robust method
    local parsed_objects
    parsed_objects=$(echo "$flat_json" | grep -o '{[^}]*}' || true)

    if [ -z "$parsed_objects" ]; then
        return 1
    fi

    # Process each JSON object
    while IFS= read -r line; do
        # Skip empty lines
        [ -z "$line" ] && continue

        # Skip lines that don't contain project objects
        if [[ ! "$line" =~ \"displayName\" ]]; then
            continue
        fi

        # Extract values using more robust regex patterns
        local display_name
        local relative_path
        local startup_cmd

        display_name=$(echo "$line" | sed -n 's/.*"displayName"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
        relative_path=$(echo "$line" | sed -n 's/.*"relativePath"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
        startup_cmd=$(echo "$line" | sed -n 's/.*"startupCmd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')

        # Add to projects array in the original format (using relativePath as folder_name)
        if [ -n "$display_name" ] && [ -n "$relative_path" ] && [ -n "$startup_cmd" ]; then
            projects+=("$display_name:$relative_path:$startup_cmd")
        fi
    done <<< "$parsed_objects"

    # Validate that we actually loaded some projects
    if [ ${#projects[@]} -eq 0 ]; then
        return 1
    fi
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

    # Check if we can write to the JSON file
    if ! touch "$json_file" 2>/dev/null; then
        print_error "Cannot write to configuration file: $json_file"
        print_error "Check directory permissions for: $(dirname "$json_file")"
        return 1
    fi

    # Start JSON array
    if ! echo "[" > "$json_file" 2>/dev/null; then
        print_error "Failed to write to configuration file: $json_file"
        return 1
    fi

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
