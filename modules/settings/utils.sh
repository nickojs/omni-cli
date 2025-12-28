#!/bin/bash

# ========================================
# Configuration Utilities Module
# ========================================
# This module provides shared utilities for JSON configuration handling
# Usage: source modules/settings/utils.sh

# Function to validate JSON configuration file
# Returns: 0 if valid, 1 if invalid
validate_json_config() {
    # Check if configuration file exists
    if [ ! -f "$JSON_CONFIG_FILE" ]; then
        print_error "No configuration file found"
        return 1
    fi

    # Check if file is empty
    if [ ! -s "$JSON_CONFIG_FILE" ]; then
        print_error "Configuration file is empty"
        return 1
    fi

    # Check if jq is available
    if ! command -v jq >/dev/null 2>&1; then
        print_error "jq is required for JSON manipulation but is not installed"
        return 1
    fi

    # Check if JSON is valid
    if ! jq empty "$JSON_CONFIG_FILE" 2>/dev/null; then
        print_error "Invalid JSON format in configuration file"
        return 1
    fi

    return 0
}

# Function to atomically update a JSON file using jq
# Uses temp file + move pattern for safe writes
# Parameters: file_path, jq_filter, [jq_args...]
# Returns: 0 if successful, 1 if error
# Usage: json_update_file "$file" 'del(.[0])'
# Usage: json_update_file "$file" '.foo = $val' --arg val "bar"
json_update_file() {
    local file="$1"
    local jq_filter="$2"
    shift 2
    local jq_args=("$@")

    local temp_file=$(mktemp)
    if jq "${jq_args[@]}" "$jq_filter" "$file" > "$temp_file" 2>/dev/null; then
        if mv "$temp_file" "$file"; then
            return 0
        fi
    fi
    rm -f "$temp_file"
    return 1
}

# Function to get projects root for a specific workspace
# Parameters: workspace_file_path
# Returns: projects root directory via echo, empty if error
get_workspace_projects_root() {
    local workspace_file="$1"

    # Get config directory
    local config_dir=$(get_config_directory)

    local workspaces_file="$config_dir/.workspaces.json"

    # First, try to get from workspaces config workspacePaths mapping
    if [ -f "$workspaces_file" ] && command -v jq >/dev/null 2>&1; then
        local workspace_path=$(jq -r --arg workspace_file "$workspace_file" \
            '.workspacePaths[$workspace_file] // empty' "$workspaces_file" 2>/dev/null)

        if [ -n "$workspace_path" ] && [ "$workspace_path" != "null" ]; then
            echo "$workspace_path"
            return 0
        fi
    fi

    # Fallback: try to extract from first project in workspace file
    if [ -f "$workspace_file" ] && command -v jq >/dev/null 2>&1; then
        local project_count=$(jq 'length' "$workspace_file" 2>/dev/null)

        if [ -n "$project_count" ] && [ "$project_count" -gt 0 ]; then
            local first_relative_path=$(jq -r ".[0].relativePath" "$workspace_file" 2>/dev/null)
            if [ -n "$first_relative_path" ] && [ "$first_relative_path" != "null" ]; then
                local projects_root=$(dirname "$first_relative_path")
                echo "$projects_root"
                return 0
            fi
        fi
    fi

    return 1
}

# Function to check if a folder is already managed
# Parameters: folder_name, projects_root_path
# Returns: 0 if managed, 1 if not managed
is_folder_managed() {
    local folder_name="$1"
    local projects_root="$2"

    if ! validate_json_config; then
        return 1
    fi

    # Check if any project has this folder as projectName
    local managed_count=$(jq --arg folder "$folder_name" \
        '[.[] | select(.projectName == $folder)] | length' \
        "$JSON_CONFIG_FILE")

    [ "$managed_count" -gt 0 ]
}

# Function to append new project to JSON config
# Parameters: display_name, folder_name, projects_root, startup_cmd, shutdown_cmd
# Returns: 0 if successful, 1 if error
add_project_to_config() {
    local display_name="$1"
    local folder_name="$2"
    local projects_root="$3"
    local startup_cmd="$4"
    local shutdown_cmd="$5"

    if ! validate_json_config; then
        print_error "Configuration file not found: $JSON_CONFIG_FILE"
        return 1
    fi

    # Create a backup of the original file (if enabled)
    local backup_file=""
    if [ "$BACKUP_JSON" = true ]; then
        backup_file="${JSON_CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
        if ! cp "$JSON_CONFIG_FILE" "$backup_file"; then
            print_error "Failed to create backup file"
            return 1
        fi
    fi

    # Create the new project object and append it
    local relative_path="${projects_root%/}/$folder_name"
    local temp_file=$(mktemp)

    if jq --arg display_name "$display_name" \
          --arg project_name "$folder_name" \
          --arg relative_path "$relative_path" \
          --arg startup_cmd "$startup_cmd" \
          --arg shutdown_cmd "$shutdown_cmd" \
          --arg folder_path "$projects_root" \
          '. += [{
              "displayName": $display_name,
              "projectName": $project_name,
              "relativePath": $relative_path,
              "startupCmd": $startup_cmd,
              "shutdownCmd": $shutdown_cmd,
              "folderPath": $folder_path
          }]' \
          "$JSON_CONFIG_FILE" > "$temp_file"; then

        # Move the temporary file to replace the original
        if mv "$temp_file" "$JSON_CONFIG_FILE"; then
            print_color "$BRIGHT_GREEN" "✓ Project added successfully"
            if [ "$BACKUP_JSON" = true ] && [ -n "$backup_file" ]; then
                print_color "$BRIGHT_CYAN" "Backup created: $backup_file"
            fi
            return 0
        else
            print_error "Failed to update configuration file"
            rm -f "$temp_file"
            return 1
        fi
    else
        print_error "Failed to process JSON with jq"
        rm -f "$temp_file"
        if [ "$BACKUP_JSON" = true ] && [ -n "$backup_file" ]; then
            rm -f "$backup_file"
        fi
        return 1
    fi
}

# Function to validate numeric input is within range
# Parameters: input, min, max, item_name (optional)
# Returns: 0 if valid, 1 if invalid
validate_number_in_range() {
    local input="$1"
    local min="$2"
    local max="$3"
    local item_name="${4:-item}"

    # Validate choice is a number
    if ! [[ "$input" =~ ^[0-9]+$ ]]; then
        print_error "Invalid choice. Please enter a number."
        return 1
    fi

    # Validate choice is in range
    if [ "$input" -lt "$min" ] || [ "$input" -gt "$max" ]; then
        print_error "Invalid choice. Please select a number between $min and $max."
        return 1
    fi

    return 0
}

# Helper function to select a project from workspace
# Parameters: workspace_file
# Returns: selected project index via echo (0-based), or empty on cancel/error
# Usage: selected_index=$(select_project_from_workspace "$workspace_file")
select_project_from_workspace() {
    local workspace_file="$1"

    # Get projects from workspace
    local workspace_projects=()
    parse_workspace_projects "$workspace_file" workspace_projects

    if [ ${#workspace_projects[@]} -eq 0 ]; then
        print_error "No projects in this workspace"
        return 1
    fi

    # Display projects with numbers
    echo -e "${BRIGHT_WHITE}Select a project:${NC}" >&2
    echo "" >&2

    local counter=1
    for project_info in "${workspace_projects[@]}"; do
        IFS=':' read -r proj_display proj_name proj_start proj_stop <<< "$project_info"
        echo -e "  ${BRIGHT_CYAN}${counter}${NC} ${BRIGHT_WHITE}${proj_display}${NC}" >&2
        counter=$((counter + 1))
    done

    echo "" >&2
    echo -ne "${BRIGHT_WHITE}Enter project number (or press Enter to cancel): ${NC}" >&2
    read -r project_choice

    # Handle empty input (cancel)
    if [ -z "$project_choice" ]; then
        return 1
    fi

    # Validate choice
    if ! validate_number_in_range "$project_choice" 1 "${#workspace_projects[@]}" "project"; then
        return 1
    fi

    # Return selected index (0-based)
    echo $((project_choice - 1))
    return 0
}
