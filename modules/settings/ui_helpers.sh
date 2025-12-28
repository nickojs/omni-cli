#!/bin/bash

# ========================================
# Settings UI Helpers Module
# ========================================
# This module provides reusable UI interaction helpers for settings screens
# Usage: source modules/settings/ui_helpers.sh

# Function to read user input with instant back key handling
# The 'b' key will trigger immediately without needing Enter
# Handles backspace properly for full editing support
# Returns: user input via variable name passed as parameter
# Usage: read_with_instant_back choice
read_with_instant_back() {
    local -n result_var=$1  # nameref to result variable
    local input=""
    local char

    while true; do
        # Read single character without echo
        IFS= read -r -s -n 1 char

        # Handle Enter (empty char from read -n 1)
        if [[ -z "$char" ]]; then
            echo ""  # Add newline
            result_var="$input"
            return 0
        fi

        # Handle backspace (ASCII 127) or ctrl-H (ASCII 8)
        if [[ "$char" == $'\x7f' ]] || [[ "$char" == $'\x08' ]]; then
            if [[ -n "$input" ]]; then
                # Remove last character from input
                input="${input%?}"
                # Move cursor back, overwrite with space, move back again
                echo -ne "\b \b"
            fi
            continue
        fi

        # Handle Ctrl+C
        if [[ "$char" == $'\x03' ]]; then
            echo ""
            result_var=""
            return 1
        fi

        # If first character is 'b' and input is empty, return immediately
        if [[ -z "$input" ]] && [[ "$char" == "b" ]]; then
            echo "b"  # Echo the character and newline
            result_var="b"
            return 0
        fi

        # Add character to input and echo it
        input+="$char"
        echo -n "$char"
    done
}

# Function to format workspace filename into display name
# Parameters: workspace_file_path
# Returns: formatted display name via echo
format_workspace_display_name() {
    local workspace_file="$1"
    local workspace_name=$(basename "$workspace_file" .json)
    echo "$workspace_name" | sed 's/[_-]/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1'
}

# Function to scan a directory for folders and let user select one
# Parameters: projects_root
# Returns: selected folder name via echo (to stdout), or empty if cancelled
# NOTE: All UI output goes to stderr (>&2) so only the selected folder goes to stdout
scan_and_display_available_folders() {
    local projects_root="$1"

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

    while IFS= read -r -d '' dir; do
        local folder_name=$(basename "$dir")

        # Skip hidden directories
        if [[ ! "$folder_name" =~ ^\. ]]; then
            available_folders+=("$folder_name")
        fi
    done < <(find "$projects_root" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)

    if [ ${#available_folders[@]} -eq 0 ]; then
        print_error "No folders found in projects directory: $projects_root" >&2
        wait_for_enter
        return 1
    fi

    # Display folders
    for i in "${!available_folders[@]}"; do
        local counter=$((i + 1))
        local folder="${available_folders[i]}"

        # Truncate long folder names
        local truncated_folder=$(printf "%.50s" "$folder")
        [ ${#folder} -gt 50 ] && truncated_folder="${truncated_folder}.."

        printf "  ${BRIGHT_CYAN}%-2s${NC}  ${BRIGHT_WHITE}%s${NC}\n" "$counter" "$truncated_folder" >&2
    done

    echo "" >&2
    echo -e "${BRIGHT_WHITE}Select a folder (enter number), or press Enter to go back${NC}" >&2
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

    # Return selected folder name to stdout
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
    local workspace_basename
    workspace_basename=$(basename "$workspace_file")

    for active_ws in "${check_array[@]}"; do
        if [ "$workspace_basename" = "$active_ws" ]; then
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
        startup_cmd="No startup command configured"
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
        ""|"y"|"yes")
            # Empty input or explicit yes
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
