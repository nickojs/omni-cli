#!/bin/bash

# ========================================
# Settings Commands Module
# ========================================
# This module handles settings menu command routing and processing
# Usage: source modules/settings/commands.sh

# Function to handle settings menu choices
handle_settings_choice() {
    local choice="$1"

    # Handle back command
    if [[ $choice =~ ^[Bb]$ ]]; then
        return 1  # Return to previous menu
    fi

    # Handle help command
    if [[ $choice =~ ^[Hh]$ ]]; then
        show_settings_help
        return 0
    fi

    # Handle add workspace command
    if [[ $choice =~ ^[Aa]$ ]]; then
        show_add_workspace_screen
        return 0
    fi

    # Handle manage workspace commands (m1, m2, etc.)
    if [[ $choice =~ ^[Mm]([0-9]+)$ ]]; then
        local workspace_choice="${BASH_REMATCH[1]}"
        handle_manage_workspace_command "$workspace_choice"
        return 0
    fi

    # Handle toggle workspace commands (t1, t2, etc.)
    if [[ $choice =~ ^[Tt]([0-9]+)$ ]]; then
        local workspace_choice="${BASH_REMATCH[1]}"
        handle_toggle_workspace_command "$workspace_choice"
        return 0
    fi
}

# Function to handle manage workspace command with workspace number
handle_manage_workspace_command() {
    local workspace_choice="$1"

    # Validate workspace number
    if [ "$workspace_choice" -lt 1 ] || [ "$workspace_choice" -gt "${#settings_workspaces[@]}" ]; then
        return 1
    fi

    # Get selected workspace
    local selected_index=$((workspace_choice - 1))
    local selected_workspace_basename="${settings_workspaces[selected_index]}"

    # Construct full path from config_dir and basename
    local config_dir=$(get_config_directory)
    local selected_workspace="$config_dir/$selected_workspace_basename"

    # Open workspace management screen
    manage_workspace "$selected_workspace"

    return 0
}

# Function to handle toggle workspace command with workspace number
handle_toggle_workspace_command() {
    local workspace_choice="$1"

    # Validate workspace number
    if [ "$workspace_choice" -lt 1 ] || [ "$workspace_choice" -gt "${#settings_workspaces[@]}" ]; then
        return 1
    fi

    # Get selected workspace
    local selected_index=$((workspace_choice - 1))
    local selected_workspace_basename="${settings_workspaces[selected_index]}"

    # Construct full path from config_dir and basename
    local config_dir=$(get_config_directory)
    local selected_workspace="$config_dir/$selected_workspace_basename"

    # Toggle the workspace
    toggle_workspace "$selected_workspace"

    return 0
}
