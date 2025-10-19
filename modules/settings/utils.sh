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

# Function to get project count from JSON config
# Returns: project count via echo, or empty if error
get_project_count() {
    if ! validate_json_config; then
        return 1
    fi

    local project_count=$(jq length "$JSON_CONFIG_FILE")
    echo "$project_count"
    return 0
}

# Function to iterate through projects with a callback
# Parameters: callback_function [additional_args...]
# Callback receives: counter, display_name, project_name, relative_path, startup_cmd, shutdown_cmd, [additional_args...]
iterate_projects() {
    local callback_function="$1"
    shift  # Remove callback function from arguments, rest are passed to callback

    if ! validate_json_config; then
        return 1
    fi

    local project_count=$(get_project_count)
    if [ -z "$project_count" ] || [ "$project_count" -eq 0 ]; then
        return 1
    fi

    # Iterate through each project
    local counter=1
    while [ $counter -le $project_count ]; do
        local index=$((counter - 1))

        # Extract project data
        local display_name=$(jq -r ".[$index].displayName" "$JSON_CONFIG_FILE")
        local project_name=$(jq -r ".[$index].projectName" "$JSON_CONFIG_FILE")
        local relative_path=$(jq -r ".[$index].relativePath" "$JSON_CONFIG_FILE")
        local startup_cmd=$(jq -r ".[$index].startupCmd" "$JSON_CONFIG_FILE")
        local shutdown_cmd=$(jq -r ".[$index].shutdownCmd // empty" "$JSON_CONFIG_FILE")

        # Call the callback function with project data and additional arguments
        "$callback_function" "$counter" "$display_name" "$project_name" "$relative_path" "$startup_cmd" "$shutdown_cmd" "$@"

        counter=$((counter + 1))
    done

    return 0
}

# Function to get specific project data by index
# Parameters: project_index (1-based)
# Returns: JSON object with project data via echo
get_project_by_index() {
    local project_index="$1"

    if ! validate_json_config; then
        return 1
    fi

    local project_count=$(get_project_count)
    if [ -z "$project_count" ] || [ "$project_index" -lt 1 ] || [ "$project_index" -gt "$project_count" ]; then
        print_error "Invalid project index: $project_index"
        return 1
    fi

    local index=$((project_index - 1))
    jq ".[$index]" "$JSON_CONFIG_FILE"
    return 0
}

# Function to extract project field by index
# Parameters: project_index (1-based), field_name
# Returns: field value via echo
get_project_field() {
    local project_index="$1"
    local field_name="$2"

    if ! validate_json_config; then
        return 1
    fi

    local project_count=$(get_project_count)
    if [ -z "$project_count" ] || [ "$project_index" -lt 1 ] || [ "$project_index" -gt "$project_count" ]; then
        print_error "Invalid project index: $project_index"
        return 1
    fi

    local index=$((project_index - 1))
    jq -r ".[$index].$field_name" "$JSON_CONFIG_FILE"
    return 0
}

# Function to get projects root for a specific workspace
# Parameters: workspace_file_path
# Returns: projects root directory via echo, empty if error
get_workspace_projects_root() {
    local workspace_file="$1"

    # Get config directory
    local config_dir
    if [ -d "config" ] && [ -f "startup.sh" ]; then
        config_dir="config"
    else
        config_dir="$HOME/.cache/fm-manager"
    fi

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

# Function to update a project in JSON configuration
# Parameters: project_index (1-based), new_display_name, new_startup_cmd, new_shutdown_cmd
# Returns: 0 if successful, 1 if error
update_project_in_config() {
    local project_index="$1"
    local new_display_name="$2"
    local new_startup_cmd="$3"
    local new_shutdown_cmd="$4"

    if ! validate_json_config; then
        print_error "Configuration file not found: $JSON_CONFIG_FILE"
        return 1
    fi

    local project_count=$(get_project_count)
    if [ -z "$project_count" ] || [ "$project_index" -lt 1 ] || [ "$project_index" -gt "$project_count" ]; then
        print_error "Invalid project index: $project_index"
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

    # Update the project using jq
    local index=$((project_index - 1))
    local temp_file=$(mktemp)

    if jq --arg display_name "$new_display_name" \
          --arg startup_cmd "$new_startup_cmd" \
          --arg shutdown_cmd "$new_shutdown_cmd" \
          ".[$index].displayName = \$display_name | .[$index].startupCmd = \$startup_cmd | .[$index].shutdownCmd = \$shutdown_cmd" \
          "$JSON_CONFIG_FILE" > "$temp_file"; then

        # Move the temporary file to replace the original
        if mv "$temp_file" "$JSON_CONFIG_FILE"; then
            print_color "$BRIGHT_GREEN" "✓ Project updated successfully"
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

# Function to remove workspace from bulk configuration
# Parameters: workspace_file_path
# Returns: 0 if successful, 1 if error
remove_workspace_from_bulk_config() {
    local workspace_file="$1"

    # Get config directory
    local config_dir
    if [ -d "config" ] && [ -f "startup.sh" ]; then
        config_dir="config"
    else
        config_dir="$HOME/.cache/fm-manager"
    fi

    local workspaces_file="$config_dir/.workspaces.json"

    if [ ! -f "$workspaces_file" ]; then
        print_error "Workspaces configuration file not found"
        return 1
    fi

    # Check if jq is available
    if ! command -v jq >/dev/null 2>&1; then
        print_error "jq is required for JSON manipulation but is not installed"
        return 1
    fi

    local temp_file=$(mktemp)

    # Remove workspace from activeConfig, availableConfigs, and workspacePaths
    if jq --arg workspace_file "$workspace_file" \
       '.activeConfig = (.activeConfig - [$workspace_file]) |
        .availableConfigs = (.availableConfigs - [$workspace_file]) |
        .workspacePaths = (.workspacePaths | del(.[$workspace_file]))' \
       "$workspaces_file" > "$temp_file"; then

        # Move the updated file (always keep the workspaces config file)
        if mv "$temp_file" "$workspaces_file"; then
            return 0
        else
            rm -f "$temp_file"
            return 1
        fi
    else
        rm -f "$temp_file"
        return 1
    fi
}

# Function to handle temp file operations with backup/restore
# Parameters: temp_file, backup_file, target_file, operation_success (0 or 1)
# Returns: 0 on success, 1 on failure
finalize_file_operation() {
    local temp_file="$1"
    local backup_file="$2"
    local target_file="$3"
    local operation_success="$4"

    if [ "$operation_success" -eq 0 ]; then
        # Operation succeeded, move temp to target
        if mv "$temp_file" "$target_file" 2>/dev/null; then
            # Success! Remove backup
            rm -f "$backup_file"
            return 0
        else
            print_error "Failed to update file"
            # Restore from backup
            [ -n "$backup_file" ] && mv "$backup_file" "$target_file" 2>/dev/null
            rm -f "$temp_file"
            return 1
        fi
    else
        # Operation failed, restore from backup
        print_error "Failed to process file"
        [ -n "$backup_file" ] && mv "$backup_file" "$target_file" 2>/dev/null
        rm -f "$temp_file"
        return 1
    fi
}
