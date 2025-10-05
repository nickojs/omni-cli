#!/bin/bash

# ========================================
# JSON Parser Module
# ========================================
# This module handles JSON parsing functionality
# Usage: source modules/config/json.sh

# Global projects array
declare -g -a projects=()
# Global workspace tracking array (parallel to projects array)
declare -g -a project_workspaces=()

# Function to load projects from active workspaces only
load_projects_from_json() {
    # Clear global arrays
    projects=()
    project_workspaces=()

    # Get config directory
    local config_dir
    if [ -d "config" ] && [ -f "startup.sh" ]; then
        config_dir="config"
    else
        config_dir="$HOME/.cache/fm-manager"
    fi

    # Check for bulk configuration file
    local bulk_config_file="$config_dir/.bulk_project_config.json"
    local workspace_files=()

    if [ -f "$bulk_config_file" ] && command -v jq >/dev/null 2>&1; then
        # Load only active workspaces from bulk configuration
        while IFS= read -r active_workspace; do
            if [ -f "$active_workspace" ]; then
                workspace_files+=("$active_workspace")
            fi
        done < <(jq -r '.activeConfig[]? // empty' "$bulk_config_file" 2>/dev/null)
    else
        # Fallback: load all JSON workspace files (excluding hidden files) for backward compatibility
        mapfile -t workspace_files < <(find "$config_dir" -name "*.json" -type f ! -name ".*" 2>/dev/null | sort)
    fi

    if [ ${#workspace_files[@]} -eq 0 ]; then
        return 1
    fi

    # Load projects from each active workspace
    for workspace_file in "${workspace_files[@]}"; do
        load_projects_from_workspace "$workspace_file"
    done

    # Validate that we actually loaded some projects
    if [ ${#projects[@]} -eq 0 ]; then
        return 1
    fi
    return 0
}

# Helper function to load projects from a single workspace file
load_projects_from_workspace() {
    local json_file="$1"

    if [ ! -f "$json_file" ]; then
        return 1
    fi

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
        local project_name
        local relative_path
        local startup_cmd
        local shutdown_cmd

        display_name=$(echo "$line" | sed -n 's/.*"displayName"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
        project_name=$(echo "$line" | sed -n 's/.*"projectName"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
        relative_path=$(echo "$line" | sed -n 's/.*"relativePath"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
        startup_cmd=$(echo "$line" | sed -n 's/.*"startupCmd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
        shutdown_cmd=$(echo "$line" | sed -n 's/.*"shutdownCmd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')

        # If no shutdown command, use empty string
        [ -z "$shutdown_cmd" ] && shutdown_cmd=""

        # Determine the folder path - prefer relativePath, fallback to projectName
        local folder_path
        if [ -n "$relative_path" ]; then
            folder_path="$relative_path"
        elif [ -n "$project_name" ]; then
            folder_path="$project_name"
        else
            continue  # Skip if neither field is available
        fi

        # Add to global projects array
        if [ -n "$display_name" ] && [ -n "$folder_path" ] && [ -n "$startup_cmd" ]; then
            projects+=("$display_name:$folder_path:$startup_cmd:$shutdown_cmd")
            project_workspaces+=("$json_file")
        fi
    done <<< "$parsed_objects"

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
