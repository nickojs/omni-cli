#!/bin/bash

# ========================================
# Layouts Menu Module
# ========================================
# This module handles layout management
# Usage: source modules/menu/layouts.sh

# Function to show layout menu in tmux popup
show_layout_menu() {
    local config_dir=$(get_config_directory)
    local layouts_dir="$config_dir/layouts"

    # Ensure layouts directory exists
    mkdir -p "$layouts_dir" 2>/dev/null

    # Get list of layout files
    local -a layout_files=()
    if [ -d "$layouts_dir" ]; then
        while IFS= read -r file; do
            layout_files+=("$file")
        done < <(find "$layouts_dir" -maxdepth 1 -name "*.json" -type f 2>/dev/null | sort)
    fi

    local layout_count=${#layout_files[@]}

    # Build the display content
    local content=""
    content+="\n"
    content+=" ${BRIGHT_WHITE}Layouts${NC}\n\n"

    if [ "$layout_count" -eq 0 ]; then
        content+=" ${DIM}No layouts configured.${NC}\n\n"
    else
        local counter=1
        for layout_file in "${layout_files[@]}"; do
            local layout_name=""
            if command -v jq >/dev/null 2>&1 && [ -f "$layout_file" ]; then
                layout_name=$(jq -r '.layoutName // empty' "$layout_file" 2>/dev/null)
            fi

            # Fallback to filename if no layoutName in JSON
            if [ -z "$layout_name" ]; then
                layout_name=$(basename "$layout_file" .json)
            fi

            content+=" ${BRIGHT_CYAN}${counter}.${NC} ${BRIGHT_WHITE}${layout_name}${NC}\n"
            counter=$((counter + 1))
        done
        content+="\n"
    fi

    content+="\n"
    content+=" ${DIM}[Press any key to close]${NC}\n"

    # Display popup (centered, 50% width, 60% height)
    tmux display-popup -E -w 50% -h 60% "printf '${content}'; read -n 1"
}
