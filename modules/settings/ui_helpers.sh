#!/bin/bash

# ========================================
# Settings UI Helpers Module
# ========================================
# This module provides reusable UI interaction helpers for settings screens
# Usage: source modules/settings/ui_helpers.sh

# Function to get the config directory path
# Returns: config directory path via echo
get_config_directory() {
    if [ -d "config" ] && [ -f "startup.sh" ]; then
        echo "config"
    else
        echo "$HOME/.cache/fm-manager"
    fi
}

# Function to prompt user to press Enter to continue
# Parameters: optional custom message
wait_for_enter() {
    local message="${1:-Press Enter to continue...}"
    echo ""
    echo -ne "${WHITE}${message}${NC}"
    read -r
}

# Function to format workspace filename into display name
# Parameters: workspace_file_path
# Returns: formatted display name via echo
format_workspace_display_name() {
    local workspace_file="$1"
    local workspace_name=$(basename "$workspace_file" .json)
    echo "$workspace_name" | sed 's/[_-]/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1'
}

# Function to scan a directory for folders and display them with managed status
# Parameters: projects_root, is_managed_check_function
# Returns: selected folder name via echo (to stdout), or empty if cancelled
# The is_managed_check_function should take (folder_name) and return 0 if managed, 1 if not
# NOTE: All UI output goes to stderr (>&2) so only the selected folder goes to stdout
scan_and_display_available_folders() {
    local projects_root="$1"
    local is_managed_check_fn="$2"

    echo "" >&2
    print_color "$BRIGHT_CYAN" "Scanning projects directory: $projects_root" >&2
    echo "" >&2

    # Check if directory exists
    if [ ! -d "$projects_root" ]; then
        print_error "Projects directory does not exist: $projects_root" >&2
        wait_for_enter
        return 1
    fi

    # Find all subdirectories
    local -a available_folders=()
    local -a managed_status=()

    while IFS= read -r -d '' dir; do
        local folder_name=$(basename "$dir")

        # Skip hidden directories and fm-manager itself
        if [[ ! "$folder_name" =~ ^\. ]] && [[ "$folder_name" != "fm-manager" ]]; then
            available_folders+=("$folder_name")

            # Check if this folder is already managed using provided function
            if $is_managed_check_fn "$folder_name"; then
                managed_status+=("managed")
            else
                managed_status+=("available")
            fi
        fi
    done < <(find "$projects_root" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)

    if [ ${#available_folders[@]} -eq 0 ]; then
        print_error "No folders found in projects directory: $projects_root" >&2
        wait_for_enter
        return 1
    fi

    # Display table header (to stderr)
    printf "  ${BRIGHT_WHITE}%-2s  %-40s  %-10s${NC}\n" "#" "Folder Name" "Status" >&2
    printf "  ${DIM}%-2s  %-40s  %-10s${NC}\n" "─" "────────────────────────────────────────" "──────────" >&2

    # Display all folders with their managed status (to stderr)
    for i in "${!available_folders[@]}"; do
        local counter=$((i + 1))
        local folder="${available_folders[i]}"
        local status="${managed_status[i]}"

        # Truncate long folder names
        local truncated_folder=$(printf "%.40s" "$folder")
        [ ${#folder} -gt 40 ] && truncated_folder="${truncated_folder}.."

        if [ "$status" = "managed" ]; then
            # Already managed - show in very dim text
            printf "  ${DIM}%-2s  %-40s  %s${NC}\n" "$counter" "$truncated_folder" "$status" >&2
        else
            # Available to add - show in white with blue number
            printf "  ${DIM}%-2s${NC}  ${BRIGHT_WHITE}%-40s${NC}  ${BRIGHT_GREEN}%s${NC}\n" "$counter" "$truncated_folder" "$status" >&2
        fi
    done

    echo "" >&2
    echo -e "${BRIGHT_WHITE}Select a folder to add (enter number), or press Enter to go back${NC}" >&2
    echo -ne "${BRIGHT_CYAN}>${NC} " >&2

    read -r folder_choice

    # Handle empty input (go back)
    if [ -z "$folder_choice" ]; then
        return 1
    fi

    # Validate choice is a number
    if ! [[ "$folder_choice" =~ ^[0-9]+$ ]]; then
        print_error "Invalid choice. Please enter a number." >&2
        wait_for_enter
        return 1
    fi

    # Validate choice is in range
    if [ "$folder_choice" -lt 1 ] || [ "$folder_choice" -gt "${#available_folders[@]}" ]; then
        print_error "Invalid choice. Please select a number between 1 and ${#available_folders[@]}." >&2
        wait_for_enter
        return 1
    fi

    # Get selected folder
    local selected_index=$((folder_choice - 1))
    local selected_folder="${available_folders[selected_index]}"
    local selected_status="${managed_status[selected_index]}"

    # Check if folder is already managed
    if [ "$selected_status" = "managed" ]; then
        print_error "Folder '$selected_folder' is already managed." >&2
        wait_for_enter
        return 1
    fi

    # Return selected folder name to stdout (only this goes to stdout!)
    echo "$selected_folder"
    return 0
}

# Function to parse projects from a workspace file
# Parameters: workspace_file
# Returns: array variable name to populate (pass by reference)
# Usage: parse_workspace_projects "$workspace_file" workspace_projects
parse_workspace_projects() {
    local workspace_file="$1"
    local -n result_array=$2  # nameref to array

    result_array=()
    if command -v jq >/dev/null 2>&1 && [ -f "$workspace_file" ]; then
        while IFS= read -r line; do
            result_array+=("$line")
        done < <(jq -r '.[] | "\(.displayName):\(.projectName):\(.startupCmd):\(.shutdownCmd)"' "$workspace_file" 2>/dev/null)
    fi
}

# Function to get projects root or return "<unknown>"
# Parameters: workspace_file
# Returns: projects root path or "<unknown>" via echo
get_projects_root_or_unknown() {
    local workspace_file="$1"

    local projects_root
    projects_root=$(get_workspace_projects_root "$workspace_file")
    if [ $? -ne 0 ] || [ -z "$projects_root" ]; then
        echo "<unknown>"
    else
        echo "$projects_root"
    fi
}

# Function to get list of active workspaces
# Parameters: none
# Returns: array variable name to populate (pass by reference)
# Usage: get_active_workspaces_list active_workspaces
get_active_workspaces_list() {
    local -n result_array=$1  # nameref to array

    result_array=()
    local config_dir=$(get_config_directory)
    local workspaces_file="$config_dir/.workspaces.json"

    if [ -f "$workspaces_file" ] && command -v jq >/dev/null 2>&1; then
        while IFS= read -r active_workspace; do
            result_array+=("$active_workspace")
        done < <(jq -r '.activeConfig[]? // empty' "$workspaces_file" 2>/dev/null)
    fi
}

# Function to check if workspace is in active list
# Parameters: workspace_file, active_workspaces_array_name
# Returns: 0 if active, 1 if not active
is_workspace_in_active_list() {
    local workspace_file="$1"
    local -n check_array=$2  # nameref to array

    for active_ws in "${check_array[@]}"; do
        if [ "$workspace_file" = "$active_ws" ]; then
            return 0
        fi
    done
    return 1
}

# Function to prompt for all project input fields
# Parameters: folder_name
# Outputs to stdout: display_name, startup_cmd, shutdown_cmd (one per line)
# Usage:
#   IFS=$'\n' read -r display_name startup_cmd shutdown_cmd < <(prompt_project_input_fields "$folder_name")
prompt_project_input_fields() {
    local folder_name="$1"

    # Get display name
    echo -e "${BRIGHT_WHITE}Enter display name for this project:${NC}" >&2
    echo -ne "${DIM}(press Enter to use '$folder_name')${NC} ${BRIGHT_CYAN}>${NC} " >&2
    read -r display_name

    if [ -z "$display_name" ]; then
        display_name="$folder_name"
    fi

    # Get startup command
    echo "" >&2
    echo -e "${BRIGHT_WHITE}Enter startup command:${NC}" >&2
    echo -ne "${DIM}(e.g., 'npm start', 'yarn dev')${NC} ${BRIGHT_CYAN}>${NC} " >&2
    read -r startup_cmd

    if [ -z "$startup_cmd" ]; then
        startup_cmd="echo 'No startup command configured'"
    fi

    # Get shutdown command
    echo "" >&2
    echo -e "${BRIGHT_WHITE}Enter shutdown command:${NC}" >&2
    echo -ne "${DIM}(e.g., 'npm run stop', 'pkill -f node')${NC} ${BRIGHT_CYAN}>${NC} " >&2
    read -r shutdown_cmd

    # Output the three values to stdout (one per line)
    echo "$display_name"
    echo "$startup_cmd"
    echo "$shutdown_cmd"
}

# Function to prompt for yes/no confirmation
# Parameters: prompt_message
# Returns: 0 for yes, 1 for no, 2 for invalid
prompt_yes_no_confirmation() {
    local prompt_message="$1"

    echo -ne "${BRIGHT_WHITE}${prompt_message} (y/n): ${NC}"
    read -r confirm_choice

    case "${confirm_choice,,}" in
        "y"|"yes")
            return 0
            ;;
        "n"|"no")
            return 1
            ;;
        *)
            return 2
            ;;
    esac
}

# Function to format project data into columns
# Parameters: display_name, folder_name, startup_cmd, shutdown_cmd, prefix
# Returns: formatted string via echo
format_project_columns() {
    local project_display_name="$1"
    local folder_name="$2"
    local startup_cmd="$3"
    local shutdown_cmd="$4"
    local prefix="$5"

    # Format data with fixed column widths: 32 | 30 | 32 | 32
    local col1="$project_display_name"
    local col2="$folder_name"
    local col3="$startup_cmd"
    local col4="$shutdown_cmd"

    # Truncate if longer than max width
    [ ${#col1} -gt 32 ] && col1=$(printf "%.29s..." "$col1")
    [ ${#col2} -gt 30 ] && col2=$(printf "%.27s..." "$col2")
    [ ${#col3} -gt 32 ] && col3=$(printf "%.29s..." "$col3")
    [ ${#col4} -gt 32 ] && col4=$(printf "%.29s..." "$col4")

    # Ensure fixed width with padding to exact column sizes
    col1=$(printf "%-32.32s" "$col1")
    col2=$(printf "%-30.30s" "$col2")
    col3=$(printf "%-32.32s" "$col3")
    col4=$(printf "%-32.32s" "$col4")

    # Return formatted row
    echo -e "  $prefix ${BRIGHT_WHITE}${col1}${NC} | ${DIM}${col2}${NC} | ${DIM}${col3}${NC} | ${DIM}${col4}${NC}"
}

# Function to show workspace management help text
show_workspace_management_help() {
    clear
    print_header "Workspace Management Help"
    echo ""
    echo -e "${BRIGHT_WHITE}This screen shows the project folders in the selected workspace.${NC}"
    echo ""
    echo -e "${BRIGHT_CYAN}Folder Status:${NC}"
    echo -e "  ${BRIGHT_GREEN}Green${NC}   - Folder exists in the projects directory"
    echo -e "  ${BRIGHT_RED}Red${NC}     - Folder is missing from the projects directory"
    echo ""
    echo -e "${BRIGHT_CYAN}Available Commands:${NC}"
    echo -e "  ${BRIGHT_GREEN}a${NC} - Add a new project to this workspace"
    echo -e "  ${BRIGHT_RED}d${NC} - Delete a project from this workspace (or delete empty workspace)"
    echo -e "  ${BRIGHT_PURPLE}b${NC} - Go back to settings menu"
    echo -e "  ${BRIGHT_PURPLE}h${NC} - Show this help screen"
    echo ""
    wait_for_enter
}
