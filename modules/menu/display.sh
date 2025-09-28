#!/bin/bash

# ========================================
# Menu Display Module
# ========================================
# This module handles menu display and UI functionality
# Usage: source modules/menu/display.sh

# Function to display menu and start project (for tmux session)
show_project_menu_tmux() {
    while true; do
        clear
        
        # Clean header
        print_header "Project Manager"

        # Display workspaces
        display_workspaces
        
        # Commands section with better formatting
        if [ ${#projects[@]} -eq 1 ]; then
            echo -e "${BRIGHT_GREEN}[1]${NC} start │ ${BRIGHT_RED}[k1, ka]${NC} kill / kill all │ ${BRIGHT_PURPLE}[s]${NC} settings │ ${BRIGHT_PURPLE}[h]${NC} help │ ${BRIGHT_PURPLE}[q]${NC} quit"
        else
            echo -e "${BRIGHT_GREEN}[1-${#projects[@]}]${NC} start │ ${BRIGHT_RED}[k1-${#projects[@]}, ka]${NC} kill / kill all │ ${BRIGHT_PURPLE}[s]${NC} settings │ ${BRIGHT_PURPLE}[h]${NC} help │ ${BRIGHT_PURPLE}[q]${NC} quit"
        fi

        # Get user input with clean prompt
        echo ""
        echo -ne "${BRIGHT_CYAN}>${NC} "
        read -r choice
        
        # Handle user input
        handle_menu_choice "$choice"
    done
}

# Function to display active configuration info
show_active_config_info() {
    # Check for bulk config file
    local config_dir
    if [ -d "config" ] && [ -f "startup.sh" ]; then
        config_dir="config"
    else
        config_dir="$HOME/.cache/fm-manager"
    fi

    local bulk_config_file="$config_dir/.bulk_project_config.json"

    if [ -f "$bulk_config_file" ] && command -v jq >/dev/null 2>&1; then
        local active_configs=$(jq -r '.activeConfig[]? // empty' "$bulk_config_file" 2>/dev/null)
        local projects_path=$(jq -r '.projectsPath // empty' "$bulk_config_file" 2>/dev/null)
        local total_configs=$(jq -r '.availableConfigs | length' "$bulk_config_file" 2>/dev/null)

        if [ -n "$active_configs" ] && [ -n "$total_configs" ]; then
            # Generate display name from active configs
            local display_name="Active Workspaces"
            if [ -n "$projects_path" ]; then
                echo -e "${BRIGHT_GREEN}●${NC} ${BRIGHT_WHITE}Projects Folder:${NC} ${DIM}${display_name} - ${projects_path}${NC}"
            else
                echo -e "${BRIGHT_GREEN}●${NC} ${BRIGHT_WHITE}Projects Folder:${NC} ${DIM}${display_name}${NC}"
            fi
            echo ""
            return
        fi
    fi

    # Fallback display
    local config_name="Default"
    if [ -n "$JSON_CONFIG_FILE" ]; then
        config_name=$(basename "$JSON_CONFIG_FILE" .json)
        config_name=$(echo "$config_name" | sed 's/[_-]/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1')
    fi

    echo -e "${BRIGHT_GREEN}●${NC} ${BRIGHT_WHITE}Projects Folder:${NC} ${DIM}${config_name}${NC}"
    echo ""
}

# Function to display workspaces and their projects with global numbering
display_workspaces() {
    # Check if any projects are loaded globally
    if [ ${#projects[@]} -eq 0 ]; then
        print_error "No workspaces configured."
        exit 1
    fi

    # Get config directory
    local config_dir
    if [ -d "config" ] && [ -f "startup.sh" ]; then
        config_dir="config"
    else
        config_dir="$HOME/.cache/fm-manager"
    fi

    # Get all JSON files (workspaces) to maintain display order
    local workspace_files
    mapfile -t workspace_files < <(find "$config_dir" -name "*.json" -type f ! -name ".*" 2>/dev/null | sort)

    local global_counter=1

    # Display each workspace with its projects using global numbering
    for workspace_file in "${workspace_files[@]}"; do
        local workspace_name=$(basename "$workspace_file" .json)
        local display_name=$(echo "$workspace_name" | sed 's/[_-]/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1')

        echo -e "${BRIGHT_CYAN}┌─ Workspace: ${BRIGHT_WHITE}$display_name${NC}"

        # Find projects belonging to this workspace
        local workspace_project_indices=()
        for i in "${!project_workspaces[@]}"; do
            if [[ "${project_workspaces[i]}" == "$workspace_file" ]]; then
                workspace_project_indices+=($i)
            fi
        done

        # Display projects for this workspace
        if [ ${#workspace_project_indices[@]} -eq 0 ]; then
            echo -e "${BRIGHT_CYAN}│${NC}  ${DIM}No projects configured${NC}"
        else
            for j in "${!workspace_project_indices[@]}"; do
                local project_index=${workspace_project_indices[j]}
                IFS=':' read -r project_display_name folder_name startup_cmd shutdown_cmd <<< "${projects[project_index]}"

                # Check if this is the last project in this workspace
                local prefix="${BRIGHT_CYAN}├─${NC}"
                if [ $((j + 1)) -eq ${#workspace_project_indices[@]} ]; then
                    prefix="${BRIGHT_CYAN}└─${NC}"
                fi

                # Get status (works for any workspace since we have global project array)
                local status_display=""
                if is_project_running "$project_display_name"; then
                    status_display="  ${BRIGHT_GREEN}●${NC} ${BRIGHT_GREEN}running${NC}"
                elif [ -d "$folder_name" ]; then
                    status_display="  ${DIM}○${NC} ${DIM}stopped${NC}"
                else
                    status_display="  ${BRIGHT_RED}✗${NC} ${BRIGHT_RED}not found${NC}"
                fi

                # Display with global counter
                echo -e "$prefix  ${BRIGHT_CYAN}$global_counter${NC}  ${BRIGHT_WHITE}${project_display_name}${NC}$status_display"
                global_counter=$((global_counter + 1))
            done
        fi
        echo ""
    done
}

