#!/bin/bash

# ========================================
# Project Display Module
# ========================================
# This module handles project display and status formatting
# Usage: source modules/project/display.sh

# Function to display project status with clean formatting
display_project_status() {
    local index="$1"
    local display_name="$2"
    local folder_name="$3"
    local startup_cmd="$4"

    local number="${BRIGHT_CYAN}$((index + 1))${NC}"

    if is_project_running "$display_name"; then
        local pane_id
        pane_id=$(get_project_pane "$display_name")
        echo -e "  ${number}  ${BRIGHT_WHITE}${display_name}${NC}  ${BRIGHT_GREEN}●${NC} ${BRIGHT_GREEN}running${NC}  ${DIM}pane ${pane_id}${NC}"
    else
        if [ -d "$folder_name" ]; then
            echo -e "  ${number}  ${BRIGHT_WHITE}${display_name}${NC}  ${DIM}○${NC} ${DIM}stopped${NC}"
        else
            echo -e "  ${number}  ${DIM}${display_name}${NC}  ${BRIGHT_RED}✗${NC} ${BRIGHT_RED}not found${NC}  ${DIM}${folder_name}${NC}"
        fi
    fi
}

# Function to list all project statuses
list_project_statuses() {
    echo -e "${BRIGHT_WHITE}${BOLD}Project Status${NC}"
    echo -e "${BRIGHT_CYAN}$(printf '─%.0s' $(seq 1 14))${NC}"
    echo ""

    for i in "${!projects[@]}"; do
        IFS=':' read -r display_name folder_name startup_cmd <<< "${projects[i]}"

        if is_project_running "$display_name"; then
            echo -e "  ${BRIGHT_CYAN}$((i + 1))${NC}  ${BRIGHT_WHITE}${display_name}${NC}  ${BRIGHT_GREEN}●${NC} ${BRIGHT_GREEN}running${NC}"
        elif [ -d "$folder_name" ]; then
            echo -e "  ${BRIGHT_CYAN}$((i + 1))${NC}  ${BRIGHT_WHITE}${display_name}${NC}  ${DIM}○${NC} ${DIM}stopped${NC}"
        else
            echo -e "  ${BRIGHT_CYAN}$((i + 1))${NC}  ${DIM}${display_name}${NC}  ${BRIGHT_RED}✗${NC} ${BRIGHT_RED}not found${NC}"
        fi
    done
}
