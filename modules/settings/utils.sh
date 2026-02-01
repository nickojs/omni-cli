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
              "folderPath": $folder_path,
              "assignedVaults": []
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

# Function to assign a vault to a project
# Parameters: workspace_file, project_path, vault_name
# Returns: 0 on success, 1 on failure
assign_vault_to_project() {
    local workspace_file="$1"
    local project_path="$2"
    local vault_name="$3"

    if [ ! -f "$workspace_file" ]; then
        return 1
    fi

    local temp_file=$(mktemp)

    # Add vault to assignedVaults if not already present
    if jq --arg path "$project_path" \
          --arg vault "$vault_name" \
          'map(if .relativePath == $path then
              if .assignedVaults == null then .assignedVaults = [] else . end |
              if (.assignedVaults | index($vault)) == null then
                  .assignedVaults += [$vault]
              else . end
           else . end)' \
          "$workspace_file" > "$temp_file"; then

        mv "$temp_file" "$workspace_file"
        return 0
    else
        rm -f "$temp_file"
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
