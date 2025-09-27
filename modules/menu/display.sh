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
        local display_name=$(jq -r '.displayName // empty' "$bulk_config_file" 2>/dev/null)
        local active_config=$(jq -r '.activeConfig // empty' "$bulk_config_file" 2>/dev/null)
        local projects_path=$(jq -r '.projectsPath // empty' "$bulk_config_file" 2>/dev/null)
        local total_configs=$(jq -r '.availableConfigs | length' "$bulk_config_file" 2>/dev/null)

        if [ -n "$display_name" ] && [ -n "$active_config" ] && [ -n "$total_configs" ]; then
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

# Function to display workspaces and their projects
display_workspaces() {
    # Get config directory
    local config_dir
    if [ -d "config" ] && [ -f "startup.sh" ]; then
        config_dir="config"
    else
        config_dir="$HOME/.cache/fm-manager"
    fi

    # Get all JSON files (workspaces)
    local workspace_files
    mapfile -t workspace_files < <(find "$config_dir" -name "*.json" -type f ! -name ".*" 2>/dev/null | sort)

    if [ ${#workspace_files[@]} -eq 0 ]; then
        print_error "No workspaces configured."
        exit 1
    fi

    # Display each workspace
    for workspace_file in "${workspace_files[@]}"; do
        local workspace_name=$(basename "$workspace_file" .json)
        local display_name=$(echo "$workspace_name" | sed 's/[_-]/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1')

        echo -e "${BRIGHT_CYAN}┌─ Workspace: ${BRIGHT_WHITE}$display_name${NC}"

        # Load projects from this workspace
        local workspace_projects=()
        if [ -f "$workspace_file" ] && command -v jq >/dev/null 2>&1; then
            # Parse JSON and extract projects for this workspace
            local json_content
            json_content=$(cat "$workspace_file" 2>/dev/null)
            if [ $? -eq 0 ] && [ -n "$json_content" ]; then
                local flat_json
                flat_json=$(echo "$json_content" | tr -d '\n\r' | sed 's/},/},\n/g')
                local parsed_objects
                parsed_objects=$(echo "$flat_json" | grep -o '{[^}]*}' || true)

                if [ -n "$parsed_objects" ]; then
                    while IFS= read -r line; do
                        [ -z "$line" ] && continue
                        if [[ ! "$line" =~ \"displayName\" ]]; then
                            continue
                        fi

                        local display_name_proj
                        local relative_path
                        local startup_cmd
                        local shutdown_cmd

                        display_name_proj=$(echo "$line" | sed -n 's/.*"displayName"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
                        relative_path=$(echo "$line" | sed -n 's/.*"relativePath"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
                        startup_cmd=$(echo "$line" | sed -n 's/.*"startupCmd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
                        shutdown_cmd=$(echo "$line" | sed -n 's/.*"shutdownCmd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')

                        [ -z "$shutdown_cmd" ] && shutdown_cmd=""

                        if [ -n "$display_name_proj" ] && [ -n "$relative_path" ] && [ -n "$startup_cmd" ]; then
                            workspace_projects+=("$display_name_proj:$relative_path:$startup_cmd:$shutdown_cmd")
                        fi
                    done <<< "$parsed_objects"
                fi
            fi
        fi

        # Display projects for this workspace
        if [ ${#workspace_projects[@]} -eq 0 ]; then
            echo -e "${BRIGHT_CYAN}│${NC}  ${DIM}No projects configured${NC}"
        else
            for i in "${!workspace_projects[@]}"; do
                IFS=':' read -r project_display_name folder_name startup_cmd shutdown_cmd <<< "${workspace_projects[i]}"

                # Check if this is the last project
                local prefix="${BRIGHT_CYAN}├─${NC}"
                if [ $((i + 1)) -eq ${#workspace_projects[@]} ]; then
                    prefix="${BRIGHT_CYAN}└─${NC}"
                fi

                # Only show status if this is the active workspace
                if [[ "$workspace_file" == "$JSON_CONFIG_FILE" ]] || [[ "$(basename "$workspace_file")" == "$(basename "$JSON_CONFIG_FILE")" ]]; then
                    # Get status for active workspace
                    local status_display=""
                    if is_project_running "$project_display_name"; then
                        status_display="  ${BRIGHT_GREEN}●${NC} ${BRIGHT_GREEN}running${NC}"
                    elif [ -d "$folder_name" ]; then
                        status_display="  ${DIM}○${NC} ${DIM}stopped${NC}"
                    else
                        status_display="  ${BRIGHT_RED}✗${NC} ${BRIGHT_RED}not found${NC}"
                    fi
                    echo -e "$prefix  ${BRIGHT_CYAN}$((i + 1))${NC}  ${BRIGHT_WHITE}${project_display_name}${NC}$status_display"
                else
                    echo -e "$prefix  ${BRIGHT_CYAN}$((i + 1))${NC}  ${BRIGHT_WHITE}${project_display_name}${NC}  ${DIM}○${NC} ${DIM}stopped${NC}"
                fi
            done
        fi
        echo ""
    done
}

