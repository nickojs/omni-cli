#!/bin/bash

# ========================================
# Project Management Module
# ========================================
# This module handles project status display and management
# Usage: source modules/project.sh

# Function to display project status with colors
display_project_status() {
    local index="$1"
    local display_name="$2"
    local folder_name="$3"
    local startup_cmd="$4"
    
    local width=$(get_terminal_width)
    local number="${BOLD}${BRIGHT_CYAN}$((index + 1)).${NC}"
    
    if is_project_running "$display_name"; then
        local pane_id
        pane_id=$(get_project_pane "$display_name")
        local status_text="$number ${BRIGHT_GREEN}$display_name${NC} ${BRIGHT_GREEN}${BOLD} RUNNING ${NC} ${DIM}(pane $pane_id)${NC} ${BRIGHT_RED}[k$((index + 1)) to kill]${NC}"
    else
        if [ -d "$folder_name" ]; then
            local status_text="$number ${WHITE}$display_name${NC} ${LIGHT_RED}${ITALIC} STOPPED ${NC} ${DIM}$startup_cmd${NC}"
        else
            local status_text="$number ${DIM}$display_name${NC} ${LIGHT_RED}${ITALIC} FOLDER NOT FOUND ${NC} ${DIM}($folder_name)${NC}"
        fi
    fi
    
    # Print the status with proper formatting
    echo -e "$status_text"
}

# Function to get project info by index
get_project_info() {
    local index="$1"
    
    if [ "$index" -ge 0 ] && [ "$index" -lt "${#projects[@]}" ]; then
        IFS=':' read -r display_name folder_name startup_cmd <<< "${projects[$index]}"
        echo "$display_name:$folder_name:$startup_cmd"
        return 0
    fi
    return 1
}

# Function to validate project folder exists
validate_project_folder() {
    local folder_name="$1"
    
    if [ -d "$folder_name" ]; then
        return 0
    else
        return 1
    fi
}

# Function to count running projects
count_running_projects() {
    local count=0
    
    for project in "${projects[@]}"; do
        IFS=':' read -r display_name folder_name startup_cmd <<< "$project"
        if is_project_running "$display_name"; then
            ((count++))
        fi
    done
    
    echo "$count"
}

# Function to list all project statuses
list_project_statuses() {
    echo "Project Status Summary:"
    echo "======================"
    
    for i in "${!projects[@]}"; do
        IFS=':' read -r display_name folder_name startup_cmd <<< "${projects[i]}"
        
        local status
        if is_project_running "$display_name"; then
            status="${BRIGHT_GREEN}RUNNING${NC}"
        elif [ -d "$folder_name" ]; then
            status="${BRIGHT_YELLOW}STOPPED${NC}"
        else
            status="${BRIGHT_RED}FOLDER NOT FOUND${NC}"
        fi
        
        echo -e "$((i + 1)). ${BRIGHT_WHITE}$display_name${NC} - $status"
    done
}

# Function to find project by name
find_project_by_name() {
    local search_name="$1"
    
    for i in "${!projects[@]}"; do
        IFS=':' read -r display_name folder_name startup_cmd <<< "${projects[i]}"
        if [[ "$display_name" == "$search_name" ]]; then
            echo "$i"
            return 0
        fi
    done
    
    return 1
}

# Function to validate project configuration
validate_project_config() {
    local project_line="$1"
    
    IFS=':' read -r display_name folder_name startup_cmd <<< "$project_line"
    
    # Check if all fields are present
    if [ -z "$display_name" ] || [ -z "$folder_name" ] || [ -z "$startup_cmd" ]; then
        return 1
    fi
    
    # Check for valid characters (basic validation)
    if [[ "$display_name" =~ [^a-zA-Z0-9\ \-\_] ]]; then
        return 1
    fi
    
    return 0
}
