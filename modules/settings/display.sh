#!/bin/bash

# ========================================
# Settings Menu Display Module
# ========================================
# This module handles settings menu display and UI functionality
# Usage: source modules/settings/display.sh

# Alternative implementation using a more responsive approach
show_settings_menu() {
    while true; do
        clear

        # Clean header
        print_header "Settings"

        # Display configuration with numbered workspaces for direct selection
        display_workspace_selector_table

        # Check if workspace management is blocked due to running projects
        local running_count=$(count_running_projects)
        if [ "$running_count" -gt 0 ]; then
            echo ""
            echo -e "${BRIGHT_YELLOW}⚠ Workspace management blocked: ${running_count} project(s) running${NC}"
            echo -e "${BRIGHT_RED}[s]${NC} select workspace │ ${BRIGHT_PURPLE}[b]${NC} back │ ${BRIGHT_PURPLE}[h]${NC} help"
        else
            echo ""
            echo -e "${BRIGHT_GREEN}[s]${NC} select workspace │ ${BRIGHT_GREEN}[a]${NC} add workspace │ ${BRIGHT_PURPLE}[b]${NC} back │ ${BRIGHT_PURPLE}[h]${NC} help"
        fi
        
        # Get user input with instant selection
        echo ""
        echo -ne "${BRIGHT_CYAN}>${NC} "

        read -n 1 -r choice
        echo # Add newline after instant selection

        # Handle command selection
        case "${choice,,}" in
            "s")
                # Check if any projects are currently running
                if ! check_no_running_projects_or_error; then
                    continue
                fi

                # Get workspace files for validation
                local config_dir=$(get_config_directory)

                local workspace_files
                mapfile -t workspace_files < <(find "$config_dir" -name "*.json" -type f ! -name ".*" 2>/dev/null | sort)

                # Go directly to workspace selection prompt
                echo ""
                echo -ne "${BRIGHT_WHITE}Select workspace: ${BRIGHT_CYAN}"
                read -r workspace_choice
                echo -ne "${NC}"

                if [[ $workspace_choice =~ ^[0-9]+$ ]]; then
                    if [ "$workspace_choice" -ge 1 ] && [ "$workspace_choice" -le "${#workspace_files[@]}" ]; then
                        handle_workspace_action_selection "$workspace_choice" "${workspace_files[@]}"
                    else
                        print_error "Invalid workspace number. Please select between 1 and ${#workspace_files[@]}."
                        echo ""
                        echo -ne "${BRIGHT_YELLOW}Press Enter to continue...${NC}"
                        read -r
                    fi
                else
                    print_error "Please enter a valid workspace number."
                    wait_for_enter
                fi
                ;;
            "a")
                # Check if any projects are currently running
                if ! check_no_running_projects_or_error; then
                    continue
                fi

                # Show add workspace flow
                show_add_workspace_screen
                ;;
            "b")
                break
                ;;
            "h")
                clear
                show_settings_help
                ;;
            *)
                # Invalid command
                echo ""
                print_error "Invalid command. Use s (select workspace), a (add workspace), b (back) or h (help)"
                wait_for_enter
                ;;
        esac
    done
}

# Function to display workspace selector table (numbered workspaces with full tree)
display_workspace_selector_table() {
    # Get config directory
    local config_dir=$(get_config_directory)

    # Get all JSON files (workspaces) to maintain display order
    local workspace_files
    mapfile -t workspace_files < <(find "$config_dir" -name "*.json" -type f ! -name ".*" 2>/dev/null | sort)

    if [ ${#workspace_files[@]} -eq 0 ]; then
        print_color "$BRIGHT_YELLOW" "No workspaces configured."
        echo ""
        return 1
    fi

    local workspace_counter=1

    # Get active workspaces list
    local active_workspaces=()
    local bulk_config_file="$config_dir/.bulk_project_config.json"
    if [ -f "$bulk_config_file" ] && command -v jq >/dev/null 2>&1; then
        while IFS= read -r active_workspace; do
            active_workspaces+=("$active_workspace")
        done < <(jq -r '.activeConfig[]? // empty' "$bulk_config_file" 2>/dev/null)
    fi

    # Display each workspace with workspace numbering and full tree structure
    for workspace_file in "${workspace_files[@]}"; do
        local display_name=$(format_workspace_display_name "$workspace_file")

        # Check if this workspace is active
        local is_workspace_active=false
        for active_ws in "${active_workspaces[@]}"; do
            if [ "$workspace_file" = "$active_ws" ]; then
                is_workspace_active=true
                break
            fi
        done

        # Display workspace header with color-coded status and numbering
        local workspace_color=""
        if [ "$is_workspace_active" = true ]; then
            workspace_color="$BRIGHT_GREEN"  # Light green for active
        else
            workspace_color="$LIGHT_RED"     # Light red for inactive
        fi

        printf "${BRIGHT_CYAN}[%s] Workspace:${NC} ${workspace_color}%s${NC}\n" "$workspace_counter" "$display_name"

        # Parse projects from this workspace file
        local workspace_projects=()
        if command -v jq >/dev/null 2>&1 && [ -f "$workspace_file" ]; then
            while IFS= read -r line; do
                workspace_projects+=("$line")
            done < <(jq -r '.[] | "\(.displayName):\(.projectName):\(.startupCmd):\(.shutdownCmd)"' "$workspace_file" 2>/dev/null)
        fi

        # Display projects for this workspace
        if [ ${#workspace_projects[@]} -eq 0 ]; then
            echo -e "  ${BRIGHT_CYAN}│${NC}  ${DIM}No projects configured${NC}"
        else
            for j in "${!workspace_projects[@]}"; do
                IFS=':' read -r project_display_name folder_name startup_cmd shutdown_cmd <<< "${workspace_projects[j]}"

                # Check if this is the last project in this workspace
                local prefix="${BRIGHT_CYAN}├─${NC}"
                if [ $((j + 1)) -eq ${#workspace_projects[@]} ]; then
                    prefix="${BRIGHT_CYAN}└─${NC}"
                fi

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

                # Display normal row with fixed table format - white text for col1, dim for col2-4
                echo -e "  $prefix ${BRIGHT_WHITE}${col1}${NC} | ${DIM}${col2}${NC} | ${DIM}${col3}${NC} | ${DIM}${col4}${NC}"
            done
        fi
        echo ""
        workspace_counter=$((workspace_counter + 1))
    done
}


# Updated workspace toggle function
handle_workspace_toggle() {
    local workspace_choice="$1"
    shift
    local workspace_files=("$@")

    # Get config directory
    local config_dir=$(get_config_directory)

    local selected_index=$((workspace_choice - 1))
    local selected_file="${workspace_files[selected_index]}"
    local display_name=$(format_workspace_display_name "$selected_file")

    # Check if this workspace is currently active
    local bulk_config_file="$config_dir/.bulk_project_config.json"
    local is_active=false

    if [ -f "$bulk_config_file" ] && command -v jq >/dev/null 2>&1; then
        # Check if the workspace is in the activeConfig array
        is_active=$(jq -r --arg workspace_file "$selected_file" \
                   'if (.activeConfig // []) | contains([$workspace_file]) then "true" else "false" end' \
                   "$bulk_config_file" 2>/dev/null)
    fi

    if [ "$is_active" = "true" ]; then
        # Workspace is currently active, inactivate it
        if remove_workspace_from_bulk_config "$selected_file"; then
            echo ""
            print_color "$BRIGHT_YELLOW" "🔘 Workspace '$display_name' inactivated"
        else
            echo ""
            print_color "$BRIGHT_RED" "❌ Failed to inactivate workspace"
        fi
    else
        # Workspace is not active, activate it
        if add_workspace_to_bulk_config "$selected_file"; then
            echo ""
            print_color "$BRIGHT_GREEN" "✓ Workspace '$display_name' activated successfully"
        else
            echo ""
            print_color "$BRIGHT_RED" "❌ Failed to activate workspace"
        fi
    fi
    wait_for_enter
}

# Function to display configuration in workspace-style table format
display_config_table() {
    local highlight_number="${1:-}"  # Optional row to highlight
    local current_mode="${2:-}"      # Optional mode for highlight color

    # Get config directory
    local config_dir=$(get_config_directory)

    # Get all JSON files (workspaces) to maintain display order
    local workspace_files
    mapfile -t workspace_files < <(find "$config_dir" -name "*.json" -type f ! -name ".*" 2>/dev/null | sort)

    if [ ${#workspace_files[@]} -eq 0 ]; then
        print_color "$BRIGHT_YELLOW" "No workspaces configured."
        echo ""
        return 1
    fi

    local global_counter=1
    local workspace_counter=1

    # Get active workspaces list
    local active_workspaces=()
    local bulk_config_file="$config_dir/.bulk_project_config.json"
    if [ -f "$bulk_config_file" ] && command -v jq >/dev/null 2>&1; then
        while IFS= read -r active_workspace; do
            active_workspaces+=("$active_workspace")
        done < <(jq -r '.activeConfig[]? // empty' "$bulk_config_file" 2>/dev/null)
    fi

    # Display each workspace with its projects using global numbering
    for workspace_file in "${workspace_files[@]}"; do
        local display_name=$(format_workspace_display_name "$workspace_file")

        # Check if this workspace is active
        local is_workspace_active=false
        for active_ws in "${active_workspaces[@]}"; do
            if [ "$workspace_file" = "$active_ws" ]; then
                is_workspace_active=true
                break
            fi
        done

        # Display workspace header with color-coded status
        local workspace_color=""
        if [ "$is_workspace_active" = true ]; then
            workspace_color="$BRIGHT_GREEN"  # Light green for active
        else
            workspace_color="$LIGHT_RED"     # Light red for inactive
        fi

        printf "  ${BRIGHT_CYAN}┌─ Workspace: ${workspace_color}%s${NC}\n" "$display_name"

        # Parse projects from this workspace file
        local workspace_projects=()
        if command -v jq >/dev/null 2>&1 && [ -f "$workspace_file" ]; then
            while IFS= read -r line; do
                workspace_projects+=("$line")
            done < <(jq -r '.[] | "\(.displayName):\(.projectName):\(.startupCmd):\(.shutdownCmd)"' "$workspace_file" 2>/dev/null)
        fi

        # Display projects for this workspace
        if [ ${#workspace_projects[@]} -eq 0 ]; then
            echo -e "  ${BRIGHT_CYAN}│${NC}  ${DIM}No projects configured${NC}"
        else
            for j in "${!workspace_projects[@]}"; do
                IFS=':' read -r project_display_name folder_name startup_cmd shutdown_cmd <<< "${workspace_projects[j]}"

                # Check if this is the last project in this workspace
                local prefix="${BRIGHT_CYAN}├─${NC}"
                if [ $((j + 1)) -eq ${#workspace_projects[@]} ]; then
                    prefix="${BRIGHT_CYAN}└─${NC}"
                fi

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

                # Display normal row with fixed table format - white text for col1, dim for col2-4
                echo -e "  $prefix ${BRIGHT_WHITE}${col1}${NC} | ${DIM}${col2}${NC} | ${DIM}${col3}${NC} | ${DIM}${col4}${NC}"

                global_counter=$((global_counter + 1))
            done
        fi
        echo ""
        workspace_counter=$((workspace_counter + 1))
    done
}

# Function to show add project screen
show_add_project_screen() {
    clear
    print_header "Add New Project"

    # Get projects root directory from existing config
    local projects_root
    projects_root=$(get_projects_root_directory)
    if [ $? -ne 0 ] || [ -z "$projects_root" ]; then
        echo ""
        print_error "Cannot determine projects directory from existing configuration"
        echo "Please make sure you have at least one project configured"
        wait_for_enter
        return 1
    fi

    # Helper function for checking if folder is managed (closure over projects_root)
    _check_folder_managed() {
        is_folder_managed "$1" "$projects_root"
    }

    # Use common folder scanning and display function
    local selected_folder
    selected_folder=$(scan_and_display_available_folders "$projects_root" "_check_folder_managed")

    # If no folder selected (empty or error), return
    if [ -z "$selected_folder" ]; then
        return 0
    fi

    # Show configuration screen for selected folder
    configure_new_project "$selected_folder" "$projects_root"
}

# Function to configure a new project
configure_new_project() {
    local folder_name="$1"
    local projects_root="$2"

    clear
    print_header "Configure New Project"
    echo ""
    print_color "$BRIGHT_CYAN" "Adding project: $folder_name"
    print_color "$DIM" "Location: ${projects_root%/}/$folder_name"
    echo ""

    # Get display name
    echo -e "${BRIGHT_WHITE}Enter display name for this project:${NC}"
    echo -ne "${DIM}(press Enter to use '$folder_name')${NC} ${BRIGHT_CYAN}>${NC} "
    read -r display_name

    if [ -z "$display_name" ]; then
        display_name="$folder_name"
    fi

    # Get startup command
    echo ""
    echo -e "${BRIGHT_WHITE}Enter startup command:${NC}"
    echo -ne "${DIM}(e.g., 'npm start', 'yarn dev')${NC} ${BRIGHT_CYAN}>${NC} "
    read -r startup_cmd

    if [ -z "$startup_cmd" ]; then
        startup_cmd="echo 'No startup command configured'"
    fi

    # Get shutdown command
    echo ""
    echo -e "${BRIGHT_WHITE}Enter shutdown command:${NC}"
    echo -ne "${DIM}(e.g., 'npm run stop', 'pkill -f node')${NC} ${BRIGHT_CYAN}>${NC} "
    read -r shutdown_cmd

    if [ -z "$shutdown_cmd" ]; then
        shutdown_cmd="echo 'No shutdown command configured'"
    fi

    # Show confirmation
    echo ""
    echo -e "${BRIGHT_WHITE}Project Configuration:${NC}"
    echo -e "  Display Name:  ${BRIGHT_GREEN}$display_name${NC}"
    echo -e "  Folder Name:   ${BRIGHT_CYAN}$folder_name${NC}"
    echo -e "  Location:      ${DIM}${projects_root%/}/$folder_name${NC}"
    echo -e "  Startup Cmd:   ${BRIGHT_YELLOW}$startup_cmd${NC}"
    echo -e "  Shutdown Cmd:  ${BRIGHT_YELLOW}$shutdown_cmd${NC}"
    echo ""

    echo -e "${BRIGHT_WHITE}Add this project to configuration? (y/n):${NC}"
    echo -ne "${BRIGHT_CYAN}>${NC} "
    read -r confirm_add

    case "${confirm_add,,}" in
        "y"|"yes")
            echo ""
            if add_project_to_config "$display_name" "$folder_name" "$projects_root" "$startup_cmd" "$shutdown_cmd"; then
                echo ""
                print_color "$BRIGHT_GREEN" "🎉 Project '$display_name' has been successfully added to configuration"
            else
                echo ""
                print_color "$BRIGHT_RED" "❌ Failed to add project to configuration"
            fi
            ;;
        "n"|"no")
            echo ""
            print_color "$BRIGHT_YELLOW" "Project addition cancelled"
            ;;
        *)
            echo ""
            print_color "$BRIGHT_RED" "Invalid choice. Project addition cancelled"
            ;;
    esac

    wait_for_enter
}



# Function to display active configuration info
show_active_config_info() {
    # Check for bulk config file
    local config_dir=$(get_config_directory)

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

# Function to handle workspace action selection (toggle or manage)
handle_workspace_action_selection() {
    local workspace_choice="$1"
    shift
    local workspace_files=("$@")

    # Get config directory
    local config_dir=$(get_config_directory)

    local selected_index=$((workspace_choice - 1))
    local selected_file="${workspace_files[selected_index]}"
    local display_name=$(format_workspace_display_name "$selected_file")

    # Check if this workspace is currently active
    local bulk_config_file="$config_dir/.bulk_project_config.json"
    local is_active=false

    if [ -f "$bulk_config_file" ] && command -v jq >/dev/null 2>&1; then
        # Check if the workspace is in the activeConfig array
        is_active=$(jq -r --arg workspace_file "$selected_file" \
                   'if (.activeConfig // []) | contains([$workspace_file]) then "true" else "false" end' \
                   "$bulk_config_file" 2>/dev/null)
    fi

    while true; do
        clear
        print_header "Workspace: $display_name"

        # Parse projects from this workspace file
        local workspace_projects=()
        if command -v jq >/dev/null 2>&1 && [ -f "$selected_file" ]; then
            while IFS= read -r line; do
                workspace_projects+=("$line")
            done < <(jq -r '.[] | "\(.displayName):\(.projectName):\(.startupCmd):\(.shutdownCmd)"' "$selected_file" 2>/dev/null)
        fi

        # Get projects root directory to show full paths
        local projects_root
        projects_root=$(get_workspace_projects_root "$selected_file")
        if [ $? -ne 0 ] || [ -z "$projects_root" ]; then
            projects_root="<unknown>"
        fi

        echo ""
        echo -e "${BRIGHT_CYAN}Workspace Location:${NC} ${DIM}$selected_file${NC}"
        echo -e "${BRIGHT_CYAN}Projects Root:${NC} ${DIM}$projects_root${NC}"

        # Show workspace status
        echo -e "${BRIGHT_CYAN}Status:${NC} $([ "$is_active" = "true" ] && echo "${BRIGHT_GREEN}Active${NC}" || echo "${LIGHT_RED}Inactive${NC}")"
        echo ""

        # Display project summary
        if [ ${#workspace_projects[@]} -eq 0 ]; then
            echo -e "${BRIGHT_YELLOW}No projects configured in this workspace${NC}"
        else
            echo -e "${BRIGHT_WHITE}Projects in this workspace (${#workspace_projects[@]}):${NC}"
            echo ""

            # Display projects in a compact format
            for i in "${!workspace_projects[@]}"; do
                IFS=':' read -r project_display_name folder_name startup_cmd shutdown_cmd <<< "${workspace_projects[i]}"

                local counter=$((i + 1))

                # Check if folder exists
                local folder_exists=false
                if [ "$projects_root" != "<unknown>" ] && [ -d "${projects_root%/}/$folder_name" ]; then
                    folder_exists=true
                fi

                # Show project with status indicator
                if [ "$folder_exists" = true ]; then
                    echo -e "  ${BRIGHT_CYAN}${counter}.${NC} ${BRIGHT_WHITE}${project_display_name}${NC} ${DIM}(${folder_name})${NC}"
                else
                    echo -e "  ${BRIGHT_CYAN}${counter}.${NC} ${BRIGHT_WHITE}${project_display_name}${NC} ${DIM}(${folder_name})${NC} ${BRIGHT_RED}[missing]${NC}"
                fi
            done
        fi

        echo ""
        echo -e "${BRIGHT_GREEN}[t]${NC} toggle active/inactive │ ${BRIGHT_PURPLE}[m]${NC} manage workspace │ ${BRIGHT_PURPLE}[b]${NC} back"
        echo ""
        echo -ne "${BRIGHT_CYAN}>${NC} "

        # Use instant selection for action choice
        read -n 1 -r action_choice
        echo # Add newline after instant selection

        case "${action_choice,,}" in
            "t")
                handle_workspace_toggle "$workspace_choice" "${workspace_files[@]}"
                # Auto return to settings after toggle
                return
                ;;
            "m")
                show_workspace_management_screen "$workspace_choice" "${workspace_files[@]}"
                # Auto return to settings after management
                return
                ;;
            "b")
                return
                ;;
            *)
                echo ""
                print_error "Invalid command. Use t (toggle), m (manage) or b (back)"
                wait_for_enter
                # Continue loop to show options again
                ;;
        esac
    done
}

# Function to show workspace management screen with project folders
show_workspace_management_screen() {
    local workspace_choice="$1"
    shift
    local workspace_files=("$@")

    # Get config directory
    local config_dir=$(get_config_directory)

    local selected_index=$((workspace_choice - 1))
    local selected_file="${workspace_files[selected_index]}"
    local display_name=$(format_workspace_display_name "$selected_file")

    while true; do
        clear
        print_header "Manage Workspace: $display_name"

        # Parse projects from this workspace file
        local workspace_projects=()
        if command -v jq >/dev/null 2>&1 && [ -f "$selected_file" ]; then
            while IFS= read -r line; do
                workspace_projects+=("$line")
            done < <(jq -r '.[] | "\(.displayName):\(.projectName):\(.startupCmd):\(.shutdownCmd)"' "$selected_file" 2>/dev/null)
        fi

        # Get projects root directory to show full paths
        local projects_root
        projects_root=$(get_workspace_projects_root "$selected_file")
        if [ $? -ne 0 ] || [ -z "$projects_root" ]; then
            projects_root="<unknown>"
        fi

        echo ""
        echo -e "${BRIGHT_CYAN}Workspace Location:${NC} ${DIM}$selected_file${NC}"
        echo -e "${BRIGHT_CYAN}Projects Root:${NC} ${DIM}$projects_root${NC}"
        echo ""

        # Display project folders table
        if [ ${#workspace_projects[@]} -eq 0 ]; then
            echo -e "${BRIGHT_YELLOW}No projects configured in this workspace${NC}"
            echo ""
            echo -e "${DIM}This workspace is empty and can be deleted if no longer needed.${NC}"
        else
            # Display table header
            printf "  ${BRIGHT_WHITE}%-3s  %-25s  %-30s${NC}\n" "#" "Display Name" "Project Folder"
            printf "  ${DIM}%-3s  %-25s  %-30s${NC}\n" "─" "────────────────────────" "──────────────────────────────"

            # Display each project with folder information
            for i in "${!workspace_projects[@]}"; do
                IFS=':' read -r project_display_name folder_name startup_cmd shutdown_cmd <<< "${workspace_projects[i]}"

                local counter=$((i + 1))

                # Truncate long names for display
                local truncated_display=$(printf "%.25s" "$project_display_name")
                [ ${#project_display_name} -gt 25 ] && truncated_display="${truncated_display}.."

                local truncated_folder=$(printf "%.30s" "$folder_name")
                [ ${#folder_name} -gt 30 ] && truncated_folder="${truncated_folder}.."

                # Check if folder exists
                local folder_exists=false
                if [ "$projects_root" != "<unknown>" ] && [ -d "${projects_root%/}/$folder_name" ]; then
                    folder_exists=true
                fi

                # Color coding: green if folder exists, red if not
                if [ "$folder_exists" = true ]; then
                    printf "  ${BRIGHT_CYAN}%-3s${NC}  ${BRIGHT_WHITE}%-25s${NC}  ${BRIGHT_GREEN}%s${NC}\n" "$counter" "$truncated_display" "$truncated_folder"
                else
                    printf "  ${BRIGHT_CYAN}%-3s${NC}  ${BRIGHT_WHITE}%-25s${NC}  ${BRIGHT_RED}%s (missing)${NC}\n" "$counter" "$truncated_display" "$truncated_folder"
                fi
            done
        fi

        echo ""
        if [ ${#workspace_projects[@]} -gt 0 ]; then
            echo -e "${BRIGHT_GREEN}[a]${NC} add project │ ${BRIGHT_RED}[d]${NC} delete project │ ${BRIGHT_PURPLE}[b]${NC} back │ ${BRIGHT_PURPLE}[h]${NC} help"
        else
            echo -e "${BRIGHT_GREEN}[a]${NC} add project │ ${BRIGHT_RED}[d]${NC} delete workspace │ ${BRIGHT_PURPLE}[b]${NC} back │ ${BRIGHT_PURPLE}[h]${NC} help"
        fi
        echo ""
        echo -ne "${BRIGHT_CYAN}>${NC} "

        read -r choice

        case "${choice,,}" in
            "a")
                show_workspace_add_project_screen "$selected_file" "$display_name"
                ;;
            "d")
                if [ ${#workspace_projects[@]} -gt 0 ]; then
                    delete_project_from_workspace "$selected_file" "${workspace_projects[@]}"
                else
                    delete_workspace "$selected_file" "$display_name"
                    if [ $? -eq 0 ]; then
                        # Workspace was deleted successfully, exit this screen
                        break
                    fi
                fi
                ;;
            "b")
                break
                ;;
            "h")
                clear
                show_workspace_management_help
                ;;
            *)
                # Invalid command
                local available_commands="a (add project), b (back) or h (help)"
                if [ ${#workspace_projects[@]} -gt 0 ]; then
                    available_commands="a (add project), d (delete project), b (back) or h (help)"
                else
                    available_commands="a (add project), d (delete workspace), b (back) or h (help)"
                fi
                echo ""
                print_error "Invalid command. Use $available_commands"
                wait_for_enter
                ;;
        esac
    done
}

# Function to show workspace management help
show_workspace_management_help() {
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
    wait_for_enter
}

# Function to show add project screen for a specific workspace
show_workspace_add_project_screen() {
    local workspace_file="$1"
    local workspace_display_name="$2"

    clear
    print_header "Add Project to Workspace: $workspace_display_name"

    # Get projects root directory for this workspace
    local projects_root
    projects_root=$(get_workspace_projects_root "$workspace_file")
    if [ $? -ne 0 ] || [ -z "$projects_root" ]; then
        echo ""
        print_error "Cannot determine projects directory for this workspace"
        print_info "This workspace may not have been properly configured with a projects folder"
        wait_for_enter
        return 1
    fi

    # Helper function for checking if folder is managed in this workspace (closure over workspace_file)
    _check_folder_managed_in_workspace() {
        is_folder_managed_in_workspace "$1" "$workspace_file"
    }

    # Use common folder scanning and display function
    local selected_folder
    selected_folder=$(scan_and_display_available_folders "$projects_root" "_check_folder_managed_in_workspace")

    # If no folder selected (empty or error), return
    if [ -z "$selected_folder" ]; then
        return 0
    fi

    # Show configuration screen for selected folder
    configure_new_workspace_project "$selected_folder" "$projects_root" "$workspace_file" "$workspace_display_name"
}

# Function to check if a folder is already managed in a specific workspace
# Parameters: folder_name, workspace_file
# Returns: 0 if managed, 1 if not managed
is_folder_managed_in_workspace() {
    local folder_name="$1"
    local workspace_file="$2"

    if [ ! -f "$workspace_file" ]; then
        return 1
    fi

    # Check if jq is available
    if ! command -v jq >/dev/null 2>&1; then
        return 1
    fi

    # Check if any project in this workspace has this folder as projectName
    local managed_count=$(jq --arg folder "$folder_name" \
        '[.[] | select(.projectName == $folder)] | length' \
        "$workspace_file" 2>/dev/null)

    [ "$managed_count" -gt 0 ]
}

# Function to configure a new project for a specific workspace
configure_new_workspace_project() {
    local folder_name="$1"
    local projects_root="$2"
    local workspace_file="$3"
    local workspace_display_name="$4"

    clear
    print_header "Configure New Project for Workspace: $workspace_display_name"
    echo ""
    print_color "$BRIGHT_CYAN" "Adding project: $folder_name"
    print_color "$DIM" "Location: ${projects_root%/}/$folder_name"
    echo ""

    # Get display name
    echo -e "${BRIGHT_WHITE}Enter display name for this project:${NC}"
    echo -ne "${DIM}(press Enter to use '$folder_name')${NC} ${BRIGHT_CYAN}>${NC} "
    read -r display_name

    if [ -z "$display_name" ]; then
        display_name="$folder_name"
    fi

    # Get startup command
    echo ""
    echo -e "${BRIGHT_WHITE}Enter startup command:${NC}"
    echo -ne "${DIM}(e.g., 'npm start', 'yarn dev')${NC} ${BRIGHT_CYAN}>${NC} "
    read -r startup_cmd

    if [ -z "$startup_cmd" ]; then
        startup_cmd="echo 'No startup command configured'"
    fi

    # Get shutdown command
    echo ""
    echo -e "${BRIGHT_WHITE}Enter shutdown command:${NC}"
    echo -ne "${DIM}(e.g., 'npm run stop', 'pkill -f node')${NC} ${BRIGHT_CYAN}>${NC} "
    read -r shutdown_cmd

    if [ -z "$shutdown_cmd" ]; then
        shutdown_cmd="echo 'No shutdown command configured'"
    fi

    # Show confirmation
    echo ""
    echo -e "${BRIGHT_WHITE}Project Configuration:${NC}"
    echo -e "  Display Name:  ${BRIGHT_GREEN}$display_name${NC}"
    echo -e "  Folder Name:   ${BRIGHT_CYAN}$folder_name${NC}"
    echo -e "  Location:      ${DIM}${projects_root%/}/$folder_name${NC}"
    echo -e "  Startup Cmd:   ${BRIGHT_YELLOW}$startup_cmd${NC}"
    echo -e "  Shutdown Cmd:  ${BRIGHT_YELLOW}$shutdown_cmd${NC}"
    echo -e "  Workspace:     ${BRIGHT_PURPLE}$workspace_display_name${NC}"
    echo ""

    echo -ne "${BRIGHT_WHITE}Add this project to workspace? (y/n): ${NC}"
    read -r confirm_add

    case "${confirm_add,,}" in
        "y"|"yes")
            echo ""
            if add_project_to_workspace "$display_name" "$folder_name" "$startup_cmd" "$shutdown_cmd" "$workspace_file"; then
                echo ""
                print_color "$BRIGHT_GREEN" "🎉 Project '$display_name' has been successfully added to workspace '$workspace_display_name'"
            else
                echo ""
                print_color "$BRIGHT_RED" "❌ Failed to add project to workspace"
            fi
            ;;
        "n"|"no")
            echo ""
            print_color "$BRIGHT_YELLOW" "Project addition cancelled"
            ;;
        *)
            echo ""
            print_color "$BRIGHT_RED" "Invalid choice. Project addition cancelled"
            ;;
    esac

    wait_for_enter
}

# Function to add project to a specific workspace JSON file
add_project_to_workspace() {
    local display_name="$1"
    local folder_name="$2"
    local startup_cmd="$3"
    local shutdown_cmd="$4"
    local workspace_file="$5"

    # Check if jq is available
    if ! command -v jq >/dev/null 2>&1; then
        print_error "jq is required for JSON manipulation but not found"
        return 1
    fi

    # Check if workspace file exists
    if [ ! -f "$workspace_file" ]; then
        print_error "Workspace file not found: $workspace_file"
        return 1
    fi

    # Create a backup of the original file
    local backup_file="${workspace_file}.backup.$(date +%s)"
    if ! cp "$workspace_file" "$backup_file"; then
        print_error "Failed to create backup of workspace file"
        return 1
    fi

    # Add the project to the JSON array
    local temp_file="${workspace_file}.tmp"

    # Get projects root directory to construct the full path
    local projects_root
    projects_root=$(get_workspace_projects_root "$workspace_file")
    if [ $? -ne 0 ] || [ -z "$projects_root" ]; then
        print_error "Cannot determine projects directory for this workspace"
        return 1
    fi

    # Construct the full path (we call it relativePath but it's actually absolute)
    local full_path="${projects_root%/}/$folder_name"

    if jq --arg display_name "$display_name" \
          --arg project_name "$folder_name" \
          --arg relative_path "$full_path" \
          --arg startup_cmd "$startup_cmd" \
          --arg shutdown_cmd "$shutdown_cmd" \
          '. += [{
              "displayName": $display_name,
              "projectName": $project_name,
              "startupCmd": $startup_cmd,
              "shutdownCmd": $shutdown_cmd,
              "relativePath": $relative_path
          }]' \
          "$workspace_file" > "$temp_file"; then

        # Replace the original file with the modified version
        if mv "$temp_file" "$workspace_file"; then
            # Remove backup file on success
            rm -f "$backup_file"
            return 0
        else
            print_error "Failed to update workspace file"
            # Restore from backup
            mv "$backup_file" "$workspace_file"
            rm -f "$temp_file"
            return 1
        fi
    else
        print_error "Failed to process JSON file"
        # Restore from backup
        mv "$backup_file" "$workspace_file"
        rm -f "$temp_file"
        return 1
    fi
}

# Function to delete a project from workspace
delete_project_from_workspace() {
    local workspace_file="$1"
    shift
    local workspace_projects=("$@")

    echo ""
    echo -ne "${BRIGHT_WHITE}Select project to delete (enter number): ${NC}"
    read -r project_choice

    # Validate choice is a number
    if ! [[ "$project_choice" =~ ^[0-9]+$ ]]; then
        echo ""
        print_error "Invalid choice. Please enter a project number."
        echo ""
        echo -ne "${BRIGHT_YELLOW}Press Enter to continue...${NC}"
        read -r
        return 1
    fi

    # Validate choice is in range
    if [ "$project_choice" -lt 1 ] || [ "$project_choice" -gt "${#workspace_projects[@]}" ]; then
        echo ""
        print_error "Invalid choice. Please select a number between 1 and ${#workspace_projects[@]}."
        echo ""
        echo -ne "${BRIGHT_YELLOW}Press Enter to continue...${NC}"
        read -r
        return 1
    fi

    # Get selected project info
    local selected_index=$((project_choice - 1))
    local selected_project="${workspace_projects[selected_index]}"
    IFS=':' read -r project_display_name folder_name startup_cmd shutdown_cmd <<< "$selected_project"

    # Show confirmation screen (new screen)
    show_delete_project_confirmation "$workspace_file" "$project_display_name" "$folder_name" "$startup_cmd" "$shutdown_cmd"
}

# Function to show delete project confirmation screen
show_delete_project_confirmation() {
    local workspace_file="$1"
    local project_display_name="$2"
    local folder_name="$3"
    local startup_cmd="$4"
    local shutdown_cmd="$5"

    clear
    print_header "Delete Project Confirmation"

    echo ""
    echo -e "${BRIGHT_YELLOW}⚠ WARNING: You are about to delete the following project:${NC}"
    echo ""
    echo -e "  ${BRIGHT_WHITE}Display Name:${NC} ${BRIGHT_CYAN}$project_display_name${NC}"
    echo -e "  ${BRIGHT_WHITE}Folder Name:${NC}  ${BRIGHT_CYAN}$folder_name${NC}"
    echo -e "  ${BRIGHT_WHITE}Startup Cmd:${NC}  ${DIM}$startup_cmd${NC}"
    echo -e "  ${BRIGHT_WHITE}Shutdown Cmd:${NC} ${DIM}$shutdown_cmd${NC}"
    echo ""
    echo -e "${BRIGHT_RED}This will remove the project from the workspace configuration.${NC}"
    echo -e "${BRIGHT_WHITE}The actual project folder will NOT be deleted.${NC}"
    echo ""
    echo -e "${BRIGHT_WHITE}Are you sure you want to delete this project? (y/N):${NC}"
    echo -ne "${BRIGHT_CYAN}>${NC} "
    read -r confirm_delete

    case "${confirm_delete,,}" in
        "y"|"yes")
            # Perform the deletion
            if delete_project_from_json "$workspace_file" "$project_display_name" "$folder_name"; then
                echo ""
                print_color "$BRIGHT_GREEN" "✓ Project '$project_display_name' has been successfully removed from workspace"
            else
                echo ""
                print_color "$BRIGHT_RED" "❌ Failed to remove project from workspace"
            fi
            ;;
        *)
            echo ""
            print_color "$BRIGHT_YELLOW" "Project deletion cancelled"
            ;;
    esac

    wait_for_enter
}

# Function to delete project from JSON file
delete_project_from_json() {
    local workspace_file="$1"
    local project_display_name="$2"
    local folder_name="$3"

    # Check if jq is available
    if ! command -v jq >/dev/null 2>&1; then
        print_error "jq is required for JSON manipulation but not found"
        return 1
    fi

    # Check if workspace file exists
    if [ ! -f "$workspace_file" ]; then
        print_error "Workspace file not found: $workspace_file"
        return 1
    fi

    # Create a backup of the original file
    local backup_file="${workspace_file}.backup.$(date +%s)"
    if ! cp "$workspace_file" "$backup_file"; then
        print_error "Failed to create backup of workspace file"
        return 1
    fi

    # Remove the project from the JSON array
    # We'll match on both displayName and projectName to ensure we delete the right project
    local temp_file="${workspace_file}.tmp"
    if jq --arg display_name "$project_display_name" --arg project_name "$folder_name" \
          'map(select(.displayName != $display_name or .projectName != $project_name))' \
          "$workspace_file" > "$temp_file"; then

        # Replace the original file with the modified version
        if mv "$temp_file" "$workspace_file"; then
            # Remove backup file on success
            rm -f "$backup_file"
            return 0
        else
            print_error "Failed to update workspace file"
            # Restore from backup
            mv "$backup_file" "$workspace_file"
            rm -f "$temp_file"
            return 1
        fi
    else
        print_error "Failed to process JSON file"
        # Restore from backup
        mv "$backup_file" "$workspace_file"
        rm -f "$temp_file"
        return 1
    fi
}

# Function to delete an entire workspace
delete_workspace() {
    local workspace_file="$1"
    local display_name="$2"

    echo ""
    echo -e "${BRIGHT_YELLOW}⚠ WARNING: You are about to delete the entire workspace:${NC}"
    echo ""
    echo -e "  ${BRIGHT_WHITE}Workspace Name:${NC} ${BRIGHT_CYAN}$display_name${NC}"
    echo -e "  ${BRIGHT_WHITE}File Location:${NC}  ${DIM}$workspace_file${NC}"
    echo ""
    echo -e "${BRIGHT_RED}This will permanently delete the workspace configuration file.${NC}"
    echo -e "${BRIGHT_WHITE}All project configurations in this workspace will be lost.${NC}"
    echo -e "${BRIGHT_WHITE}The actual project folders will NOT be deleted.${NC}"
    echo ""

    # Check if this workspace is currently active
    local config_dir=$(get_config_directory)

    local bulk_config_file="$config_dir/.bulk_project_config.json"
    local is_active=false

    if [ -f "$bulk_config_file" ] && command -v jq >/dev/null 2>&1; then
        # Check if the workspace is in the activeConfig array
        is_active=$(jq -r --arg workspace_file "$workspace_file" \
                   'if (.activeConfig // []) | contains([$workspace_file]) then "true" else "false" end' \
                   "$bulk_config_file" 2>/dev/null)
    fi

    if [ "$is_active" = "true" ]; then
        echo -e "${BRIGHT_YELLOW}⚠ This workspace is currently ACTIVE and will be deactivated.${NC}"
        echo ""
    fi

    echo -e "${BRIGHT_WHITE}Are you sure you want to delete this workspace? (y/N):${NC}"
    echo -ne "${BRIGHT_CYAN}>${NC} "
    read -r confirm_delete

    case "${confirm_delete,,}" in
        "y"|"yes")
            # If workspace is active, remove it from bulk config first
            if [ "$is_active" = "true" ]; then
                echo ""
                print_color "$BRIGHT_YELLOW" "Deactivating workspace..."
                if ! remove_workspace_from_bulk_config "$workspace_file"; then
                    print_color "$BRIGHT_RED" "❌ Failed to deactivate workspace, deletion cancelled"
                    wait_for_enter
                    return 1
                fi
            fi

            # Create a backup before deletion
            local backup_file="${workspace_file}.deleted.$(date +%s)"
            if cp "$workspace_file" "$backup_file" 2>/dev/null; then
                # Delete the workspace file
                if rm -f "$workspace_file"; then
                    echo ""
                    print_color "$BRIGHT_GREEN" "✓ Workspace '$display_name' has been successfully deleted"
                    print_color "$DIM" "Backup saved as: $backup_file"
                    wait_for_enter
                    return 0
                else
                    print_color "$BRIGHT_RED" "❌ Failed to delete workspace file"
                    wait_for_enter
                    return 1
                fi
            else
                print_color "$BRIGHT_RED" "❌ Failed to create backup, deletion cancelled"
                wait_for_enter
                return 1
            fi
            ;;
        *)
            echo ""
            print_color "$BRIGHT_YELLOW" "Workspace deletion cancelled"
            wait_for_enter
            return 1
            ;;
    esac
}

# Function to show add workspace screen
show_add_workspace_screen() {
    clear
    print_header "Add New Workspace"
    echo ""
    print_color "$BRIGHT_CYAN" "Use the file navigator to select a workspace folder"
    wait_for_enter

    # Use the navigator module to select workspace folder
    # Reset the SELECTED_PROJECTS_DIR variable
    unset SELECTED_PROJECTS_DIR

    # Call the navigator
    show_interactive_browser

    # Check if a directory was selected
    if [ -z "$SELECTED_PROJECTS_DIR" ]; then
        clear
        print_warning "No workspace folder selected"
        wait_for_enter
        return 1
    fi

    # Convert to absolute path
    local workspace_folder=$(realpath "$SELECTED_PROJECTS_DIR")

    # Get workspace name from user
    clear
    print_header "Configure New Workspace"
    echo ""
    print_color "$BRIGHT_CYAN" "Selected folder: $workspace_folder"
    echo ""

    # Suggest a workspace name based on folder
    local suggested_name=$(basename "$workspace_folder" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')

    echo -e "${BRIGHT_WHITE}Enter workspace name:${NC}"
    echo -ne "${DIM}(press Enter to use '$suggested_name')${NC} ${BRIGHT_CYAN}>${NC} "
    read -r workspace_name

    if [ -z "$workspace_name" ]; then
        workspace_name="$suggested_name"
    fi

    # Sanitize workspace name (replace spaces with underscores, lowercase)
    workspace_name=$(echo "$workspace_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd '[:alnum:]_-')

    # Get config directory
    local config_dir=$(get_config_directory)
    mkdir -p "$config_dir"

    local workspace_file="$config_dir/${workspace_name}.json"

    # Check if workspace already exists
    if [ -f "$workspace_file" ]; then
        echo ""
        print_error "A workspace with name '$workspace_name' already exists!"
        wait_for_enter
        return 1
    fi

    # Create empty workspace JSON file
    if echo '[]' | jq . > "$workspace_file"; then
        echo ""
        print_color "$BRIGHT_GREEN" "✓ Workspace '$workspace_name' created successfully"
        print_color "$DIM" "Location: $workspace_file"
        print_color "$DIM" "Projects folder: $workspace_folder"

        # Ask if user wants to activate the workspace
        echo ""
        echo -e "${BRIGHT_WHITE}Activate this workspace now? (y/n):${NC}"
        echo -ne "${BRIGHT_CYAN}>${NC} "
        read -r activate_choice

        case "${activate_choice,,}" in
            "y"|"yes")
                if add_workspace_to_bulk_config "$workspace_file" "$workspace_folder"; then
                    echo ""
                    print_color "$BRIGHT_GREEN" "✓ Workspace activated successfully"
                else
                    echo ""
                    print_color "$BRIGHT_RED" "❌ Failed to activate workspace"
                fi
                ;;
            *)
                echo ""
                print_color "$BRIGHT_YELLOW" "Workspace created but not activated"
                print_color "$DIM" "Note: You'll need to add this workspace to bulk config manually"
                ;;
        esac
    else
        print_error "Failed to create workspace file"
        return 1
    fi

    wait_for_enter
}