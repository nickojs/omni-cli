#!/bin/bash

# ========================================
# State Management Module
# ========================================
# This module provides centralized workspace state management
# Usage: source modules/settings/state.sh

# Constants
readonly WORKSPACES_FILE=".workspaces.json"

# Function to get the workspaces configuration file path
# Returns: absolute path to .workspaces.json via echo
get_workspaces_file_path() {
    local config_dir=$(get_config_directory)
    echo "$config_dir/$WORKSPACES_FILE"
}

# Function to ensure workspaces file exists with valid structure
# Returns: 0 if successful, 1 if error
ensure_workspaces_file() {
    local workspaces_file=$(get_workspaces_file_path)

    # If file doesn't exist, create empty structure
    if [ ! -f "$workspaces_file" ]; then
        local config_dir=$(dirname "$workspaces_file")
        mkdir -p "$config_dir" 2>/dev/null || return 1

        echo '{"activeConfig": [], "projectsPath": "", "availableConfigs": [], "workspacePaths": {}}' > "$workspaces_file"
        return $?
    fi

    # Validate existing file
    if ! command -v jq >/dev/null 2>&1; then
        return 1
    fi

    if ! jq empty "$workspaces_file" 2>/dev/null; then
        # Invalid JSON, recreate with empty structure
        echo '{"activeConfig": [], "projectsPath": "", "availableConfigs": [], "workspacePaths": {}}' > "$workspaces_file"
        return $?
    fi

    return 0
}

# Function to get list of active workspace file paths
# Parameters: result_array_nameref (pass by reference)
# Returns: 0 if successful, 1 if error
# Usage: get_active_workspaces active_workspaces_array
get_active_workspaces() {
    local -n result_array=$1
    result_array=()

    if ! ensure_workspaces_file; then
        return 1
    fi

    local workspaces_file=$(get_workspaces_file_path)

    if ! command -v jq >/dev/null 2>&1; then
        return 1
    fi

    while IFS= read -r workspace; do
        [ -n "$workspace" ] && result_array+=("$workspace")
    done < <(jq -r '.activeConfig[]? // empty' "$workspaces_file" 2>/dev/null)

    return 0
}

# Function to get list of all available workspace file paths
# Parameters: result_array_nameref (pass by reference)
# Returns: 0 if successful, 1 if error
# Usage: get_available_workspaces available_workspaces_array
get_available_workspaces() {
    local -n result_array=$1
    result_array=()

    if ! ensure_workspaces_file; then
        return 1
    fi

    local workspaces_file=$(get_workspaces_file_path)

    if ! command -v jq >/dev/null 2>&1; then
        return 1
    fi

    while IFS= read -r workspace; do
        [ -n "$workspace" ] && result_array+=("$workspace")
    done < <(jq -r '.availableConfigs[]? // empty' "$workspaces_file" 2>/dev/null)

    return 0
}

# Function to check if a workspace is active
# Parameters: workspace_file_path
# Returns: 0 if active, 1 if not active or error
is_workspace_active() {
    local workspace_file="$1"
    local workspace_basename
    workspace_basename=$(basename "$workspace_file")

    local active_workspaces=()
    if ! get_active_workspaces active_workspaces; then
        return 1
    fi

    for active_ws in "${active_workspaces[@]}"; do
        if [ "$workspace_basename" = "$active_ws" ]; then
            return 0
        fi
    done

    return 1
}

# Function to get the first active workspace
# Returns: workspace file path via echo, or empty if none active
get_primary_active_workspace() {
    if ! ensure_workspaces_file; then
        return 1
    fi

    local workspaces_file=$(get_workspaces_file_path)

    if ! command -v jq >/dev/null 2>&1; then
        return 1
    fi

    local primary=$(jq -r '.activeConfig[0]? // empty' "$workspaces_file" 2>/dev/null)
    echo "$primary"
    [ -n "$primary" ] && return 0 || return 1
}

# Function to add workspace to active configuration
# Parameters: workspace_file_path, [projects_folder_path]
# Returns: 0 if successful, 1 if error
activate_workspace() {
    local workspace_file="$1"
    local projects_folder="${2:-}"

    if [ ! -f "$workspace_file" ]; then
        return 1
    fi

    if ! ensure_workspaces_file; then
        return 1
    fi

    if ! command -v jq >/dev/null 2>&1; then
        return 1
    fi

    # Store only the basename to keep paths clean and portable
    local workspace_basename
    workspace_basename=$(basename "$workspace_file")

    local workspaces_file=$(get_workspaces_file_path)

    # If projects_folder not provided, try to get from existing config or use dirname
    if [ -z "$projects_folder" ]; then
        projects_folder=$(dirname "$workspace_file")
    fi

    local temp_file=$(mktemp)

    if jq --arg workspace_file "$workspace_basename" \
       --arg projects_path "$projects_folder" \
       '.activeConfig = (.activeConfig + [$workspace_file] | unique) |
        .projectsPath = $projects_path |
        .availableConfigs = (.availableConfigs + [$workspace_file] | unique) |
        .workspacePaths = (.workspacePaths // {} | . + {($workspace_file): $projects_path})' \
       "$workspaces_file" > "$temp_file"; then

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

# Function to deactivate a workspace (remove from activeConfig only)
# Parameters: workspace_file_path
# Returns: 0 if successful, 1 if error
deactivate_workspace() {
    local workspace_file="$1"

    if ! ensure_workspaces_file; then
        return 1
    fi

    if ! command -v jq >/dev/null 2>&1; then
        return 1
    fi

    # Use only the basename for consistency
    local workspace_basename
    workspace_basename=$(basename "$workspace_file")

    local workspaces_file=$(get_workspaces_file_path)
    local temp_file=$(mktemp)

    if jq --arg workspace_file "$workspace_basename" \
       '.activeConfig = (.activeConfig - [$workspace_file])' \
       "$workspaces_file" > "$temp_file"; then

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

# Function to register a new workspace (add to availableConfigs)
# Parameters: workspace_file_path, projects_folder_path
# Returns: 0 if successful, 1 if error
register_workspace() {
    local workspace_file="$1"
    local projects_folder="$2"

    if [ ! -f "$workspace_file" ]; then
        return 1
    fi

    if ! ensure_workspaces_file; then
        return 1
    fi

    if ! command -v jq >/dev/null 2>&1; then
        return 1
    fi

    # Store only the basename to keep paths clean and portable
    local workspace_basename
    workspace_basename=$(basename "$workspace_file")

    local workspaces_file=$(get_workspaces_file_path)
    local temp_file=$(mktemp)

    if jq --arg workspace_file "$workspace_basename" \
       --arg projects_path "$projects_folder" \
       '.availableConfigs = (.availableConfigs + [$workspace_file] | unique) |
        .workspacePaths = (.workspacePaths // {} | . + {($workspace_file): $projects_path})' \
       "$workspaces_file" > "$temp_file"; then

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

# Function to completely remove a workspace from the system
# Parameters: workspace_file_path
# Returns: 0 if successful, 1 if error
unregister_workspace() {
    local workspace_file="$1"

    if ! ensure_workspaces_file; then
        return 1
    fi

    if ! command -v jq >/dev/null 2>&1; then
        return 1
    fi

    # Use only the basename for consistency
    local workspace_basename
    workspace_basename=$(basename "$workspace_file")

    local workspaces_file=$(get_workspaces_file_path)
    local temp_file=$(mktemp)

    if jq --arg workspace_file "$workspace_basename" \
       '.activeConfig = (.activeConfig - [$workspace_file]) |
        .availableConfigs = (.availableConfigs - [$workspace_file]) |
        .workspacePaths = (.workspacePaths | del(.[$workspace_file]))' \
       "$workspaces_file" > "$temp_file"; then

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

# Function to get projects folder path for a workspace
# Parameters: workspace_file_path
# Returns: projects folder path via echo, or empty if not found
get_workspace_projects_folder() {
    local workspace_file="$1"

    if ! ensure_workspaces_file; then
        return 1
    fi

    if ! command -v jq >/dev/null 2>&1; then
        return 1
    fi

    # Use only the basename for looking up in workspacePaths
    local workspace_basename
    workspace_basename=$(basename "$workspace_file")

    local workspaces_file=$(get_workspaces_file_path)
    local projects_folder=$(jq -r --arg workspace_file "$workspace_basename" \
        '.workspacePaths[$workspace_file]? // empty' "$workspaces_file" 2>/dev/null)

    if [ -n "$projects_folder" ]; then
        echo "$projects_folder"
        return 0
    fi

    return 1
}

# Function to validate workspace state
# Returns: 0 if valid, 1 if issues found (prints issues to stderr)
validate_workspace_state() {
    if ! ensure_workspaces_file; then
        echo "Error: Cannot access workspaces file" >&2
        return 1
    fi

    local workspaces_file=$(get_workspaces_file_path)
    local has_issues=0

    # Get active workspaces
    local active_workspaces=()
    get_active_workspaces active_workspaces

    # Check if active workspace files exist
    for workspace in "${active_workspaces[@]}"; do
        if [ ! -f "$workspace" ]; then
            echo "Warning: Active workspace file not found: $workspace" >&2
            has_issues=1
        fi
    done

    # Get available workspaces
    local available_workspaces=()
    get_available_workspaces available_workspaces

    # Check if available workspace files exist
    for workspace in "${available_workspaces[@]}"; do
        if [ ! -f "$workspace" ]; then
            echo "Warning: Available workspace file not found: $workspace" >&2
            has_issues=1
        fi
    done

    return $has_issues
}

# Function to clean orphaned workspace entries
# Returns: 0 if successful, 1 if error
clean_orphaned_workspaces() {
    if ! ensure_workspaces_file; then
        return 1
    fi

    if ! command -v jq >/dev/null 2>&1; then
        return 1
    fi

    local workspaces_file=$(get_workspaces_file_path)
    local temp_file=$(mktemp)

    # Build arrays of existing workspace files
    local active_workspaces=()
    get_active_workspaces active_workspaces

    local valid_active=()
    for workspace in "${active_workspaces[@]}"; do
        [ -f "$workspace" ] && valid_active+=("$workspace")
    done

    local available_workspaces=()
    get_available_workspaces available_workspaces

    local valid_available=()
    for workspace in "${available_workspaces[@]}"; do
        [ -f "$workspace" ] && valid_available+=("$workspace")
    done

    # Rebuild the workspaces file with only valid entries
    local active_json=$(printf '%s\n' "${valid_active[@]}" | jq -R . | jq -s .)
    local available_json=$(printf '%s\n' "${valid_available[@]}" | jq -R . | jq -s .)

    if jq --argjson active "$active_json" \
       --argjson available "$available_json" \
       '.activeConfig = $active | .availableConfigs = $available' \
       "$workspaces_file" > "$temp_file"; then

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
