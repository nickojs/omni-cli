#!/bin/bash

# ========================================
# Project Display Module
# ========================================
# This module handles project display and status formatting
# Usage: source modules/project/display.sh

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
