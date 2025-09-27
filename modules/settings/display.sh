#!/bin/bash

# ========================================
# Settings Menu Display Module
# ========================================
# This module handles settings menu display and UI functionality
# Usage: source modules/settings/display.sh

# Alternative implementation using a more responsive approach
show_settings_menu() {
    local current_mode=""  # Can be "delete" or "edit"
    
    while true; do
        clear
        
        # Clean header
        print_header "Settings"

        # Display active configuration info
        show_active_config_info

        # Display configuration directly in the menu
        display_config_table
        echo ""

        if [ "$current_mode" = "delete" ]; then
            echo -e "${BRIGHT_RED}●${NC} delete mode"
        elif [ "$current_mode" = "edit" ]; then
            echo -e "${BRIGHT_BLUE}●${NC} edit mode"
        elif [ "$current_mode" = "add" ]; then
            echo -e "${BRIGHT_GREEN}●${NC} add mode"
        else
            echo -e "${DIM}○${NC} no mode selected │ ${BRIGHT_RED}[d]${NC} delete │ ${BRIGHT_BLUE}[e]${NC} edit │ ${BRIGHT_GREEN}[a]${NC} add"
        fi
        echo ""

        echo -e "${BRIGHT_PURPLE}[p]${NC} projects │ ${BRIGHT_PURPLE}[b]${NC} back │ ${BRIGHT_PURPLE}[h]${NC} help"
        
        # Get user input with clean prompt
        echo ""
        if [ "$current_mode" = "delete" ]; then
            echo -ne "${DIM}Select project to ${BRIGHT_RED}delete${NC} ${DIM}(Enter to return)${NC} ${BRIGHT_CYAN}>${NC} "
        elif [ "$current_mode" = "edit" ]; then
            echo -ne "${DIM}Select project to ${BRIGHT_BLUE}edit${NC} ${DIM}(Enter to return)${NC} ${BRIGHT_CYAN}>${NC} "
        elif [ "$current_mode" = "add" ]; then
            echo -ne "${DIM}${BRIGHT_GREEN}Add mode${NC} ${DIM}activated${NC} ${BRIGHT_CYAN}>${NC} "
        else
            echo -ne "${BRIGHT_CYAN}>${NC} "
        fi
        
        IFS= read -r -n1 -s choice

        # Handle Enter key in delete/edit/add mode - return to normal settings menu
        if [[ "$choice" == $'\n' || "$choice" == $'\r' || -z "$choice" ]] && ([ "$current_mode" = "delete" ] || [ "$current_mode" = "edit" ] || [ "$current_mode" = "add" ]); then
            current_mode=""
            echo -e "${BRIGHT_YELLOW}Returned to Settings menu${NC}"
            sleep 0.5
            continue
        fi

        # Handle direct mode selection
        if [[ $choice =~ ^[Dd]$ ]]; then
            current_mode="delete"
            echo -e "${BRIGHT_RED}✓ Delete mode activated${NC}"
            sleep 0.5
            continue
        fi

        if [[ $choice =~ ^[Ee]$ ]]; then
            current_mode="edit"
            echo -e "${BRIGHT_BLUE}✓ Edit mode activated${NC}"
            sleep 0.5
            continue
        fi

        if [[ $choice =~ ^[Aa]$ ]]; then
            current_mode="add"
            echo -e "${BRIGHT_GREEN}✓ Add mode activated${NC}"
            sleep 0.5
            show_add_project_screen
            current_mode=""
            continue
        fi
        
        # Handle navigation commands (disabled in edit mode)
        if [ "$current_mode" != "edit" ] && [ "$current_mode" != "add" ]; then
            case "${choice,,}" in
                "b")
                    break
                    ;;
                "h")
                    clear
                    show_settings_help
                    continue
                    ;;
            esac
        fi
        
        # Handle project selection when in delete/edit mode
        if [ "$current_mode" = "delete" ] || [ "$current_mode" = "edit" ]; then
            # Check if input is a number
            if [[ $choice =~ ^[0-9]+$ ]]; then
                # Validate project selection
                if validate_json_config; then
                    local project_count=$(get_project_count)
                    
                    if [ "$choice" -ge 1 ] && [ "$choice" -le "$project_count" ]; then
                        # Clear screen and show highlighted selection
                        clear
                        print_header "Settings"
                        
                        # Display configuration with highlighted selection
                        display_config_table "$choice" "$current_mode"

                        # Get project data
                        local display_name=$(get_project_field "$choice" "displayName")
                        local project_name=$(get_project_field "$choice" "projectName")

                        echo ""
                        if [ "$current_mode" = "delete" ]; then
                            # Show confirmation prompt for deletion
                            echo -e "${BRIGHT_RED}⚠️  CONFIRM DELETION${NC}"
                            echo -e "Are you sure you want to ${BRIGHT_RED}DELETE${NC} project: ${BRIGHT_YELLOW}$display_name${NC} (${BRIGHT_CYAN}$project_name${NC})?"
                            echo -e "${BRIGHT_WHITE}Type [y] to confirm deletion, [n] to cancel${NC}"

                            echo -ne "${BRIGHT_CYAN}>>${NC} "
                            read -r confirm_choice

                            case "${confirm_choice,,}" in
                                "y"|"yes")
                                    echo -e "${BRIGHT_RED}✓ Project deletion confirmed${NC}"
                                    echo ""

                                    # Extract full project data for deletion
                                    local relative_path=$(get_project_field "$choice" "relativePath")

                                    # Call the removal function
                                    if remove_project_from_config "$display_name" "$project_name" "$relative_path"; then
                                        echo ""
                                        print_color "$BRIGHT_GREEN" "🗑️  Project '$display_name' has been successfully removed from configuration"
                                    else
                                        echo ""
                                        print_color "$BRIGHT_RED" "❌ Failed to remove project from configuration"
                                    fi
                                    ;;
                                "n"|"no")
                                    echo -e "${BRIGHT_YELLOW}Deletion cancelled${NC}"
                                    sleep 0.5
                                    ;;
                                *)
                                    echo -e "${BRIGHT_RED}Invalid choice. Deletion cancelled${NC}"
                                    sleep 0.5
                                    ;;
                            esac
                        else
                            # Edit mode - go directly to editing without confirmation
                            echo -e "${BRIGHT_BLUE}📝  EDIT PROJECT${NC}"
                            echo -e "${BRIGHT_YELLOW}$display_name${NC} (${BRIGHT_CYAN}$project_name${NC})"
                            echo ""

                            # Get current values
                            local current_display_name=$(get_project_field "$choice" "displayName")
                            local current_startup_cmd=$(get_project_field "$choice" "startupCmd")
                            local current_shutdown_cmd=$(get_project_field "$choice" "shutdownCmd")

                            echo -e "${BRIGHT_WHITE}Current values:${NC}"
                            echo -e "  Display Name:  ${BRIGHT_CYAN}$current_display_name${NC}"
                            echo -e "  Startup Cmd:   ${BRIGHT_CYAN}$current_startup_cmd${NC}"
                            echo -e "  Shutdown Cmd:  ${BRIGHT_CYAN}$current_shutdown_cmd${NC}"
                            echo ""

                            # Get new display name
                            echo -e "${BRIGHT_WHITE}Enter new display name (press Enter to keep current):${NC}"
                            echo -ne "${BRIGHT_CYAN}>${NC} "
                            read -r new_display_name
                            if [ -z "$new_display_name" ]; then
                                new_display_name="$current_display_name"
                            fi

                            # Get new startup command
                            echo -e "${BRIGHT_WHITE}Enter new startup command (press Enter to keep current):${NC}"
                            echo -ne "${BRIGHT_CYAN}>${NC} "
                            read -r new_startup_cmd
                            if [ -z "$new_startup_cmd" ]; then
                                new_startup_cmd="$current_startup_cmd"
                            fi

                            # Get new shutdown command
                            echo -e "${BRIGHT_WHITE}Enter new shutdown command (press Enter to keep current):${NC}"
                            echo -ne "${BRIGHT_CYAN}>${NC} "
                            read -r new_shutdown_cmd
                            if [ -z "$new_shutdown_cmd" ]; then
                                new_shutdown_cmd="$current_shutdown_cmd"
                            fi

                            # Check if any changes were made
                            if [ "$new_display_name" = "$current_display_name" ] && [ "$new_startup_cmd" = "$current_startup_cmd" ] && [ "$new_shutdown_cmd" = "$current_shutdown_cmd" ]; then
                                echo -e "${BRIGHT_YELLOW}No changes made${NC}"
                            else
                                echo ""
                                echo -e "${BRIGHT_WHITE}Updating project with:${NC}"
                                echo -e "  Display Name:  ${BRIGHT_GREEN}$new_display_name${NC}"
                                echo -e "  Startup Cmd:   ${BRIGHT_GREEN}$new_startup_cmd${NC}"
                                echo -e "  Shutdown Cmd:  ${BRIGHT_GREEN}$new_shutdown_cmd${NC}"
                                echo ""

                                # Update the project
                                if update_project_in_config "$choice" "$new_display_name" "$new_startup_cmd" "$new_shutdown_cmd"; then
                                    echo ""
                                    print_color "$BRIGHT_GREEN" "🎉 Project '$current_display_name' has been successfully updated"
                                else
                                    echo ""
                                    print_color "$BRIGHT_RED" "❌ Failed to update project"
                                fi
                            fi
                        fi
                        echo ""
                        echo -e "${BRIGHT_WHITE}Press Enter to continue...${NC}"
                        read -r
                        # Return to main settings menu after operation
                        current_mode=""
                    else
                        echo ""
                        print_error "Invalid project number. Please select a number between 1 and $project_count."
                        echo -e "${BRIGHT_YELLOW}Press Enter to continue...${NC}"
                        read -r
                        # Return to main settings menu after error
                        current_mode=""
                    fi
                else
                    print_error "Unable to validate project selection. Configuration may be missing or invalid."
                    echo -e "${BRIGHT_YELLOW}Press Enter to continue...${NC}"
                    read -r
                    # Return to main settings menu after error
                    current_mode=""
                fi
            else
                echo ""
                print_error "Please enter a valid project number or use [m] to change mode, [b] to go back."
                echo -e "${BRIGHT_YELLOW}Press Enter to continue...${NC}"
                read -r
                # Return to main settings menu after error
                current_mode=""
            fi
        else
            # No mode selected, handle as regular command
            if ! handle_settings_choice "$choice" "$current_mode"; then
                break
            fi
        fi
    done
}

# Function to remove a project from JSON configuration
remove_project_from_config() {
    local target_display_name="$1"
    local target_project_name="$2"
    local target_relative_path="$3"

    # Validate configuration using shared utility
    if ! validate_json_config; then
        print_error "Configuration file not found: $JSON_CONFIG_FILE"
        return 1
    fi

    # Get current project count using shared utility
    local project_count=$(get_project_count)
    if [ -z "$project_count" ]; then
        return 1
    fi

    # Create a backup of the original file (if enabled)
    local backup_file=""
    if [ "$BACKUP_JSON" = true ]; then
        backup_file="${JSON_CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
        if ! cp "$JSON_CONFIG_FILE" "$backup_file"; then
            print_error "Failed to create backup file"
            return 1
        fi
    fi

    # Check if there's only one project - if so, remove the entire JSON file
    if [ "$project_count" -eq 1 ]; then
        # Remove the entire JSON file since this is the last project
        if rm "$JSON_CONFIG_FILE"; then
            print_color "$BRIGHT_GREEN" "✓ Last project removed - JSON configuration file deleted"
            if [ "$BACKUP_JSON" = true ] && [ -n "$backup_file" ]; then
                print_color "$BRIGHT_CYAN" "Backup created: $backup_file"
            fi
            print_color "$BRIGHT_WHITE" "Configuration file removed (was the last project)"
            return 0
        else
            print_error "Failed to remove configuration file"
            return 1
        fi
    fi

    # Remove the matching project using jq
    # Using negation that works with all jq versions
    local temp_file=$(mktemp)
    if jq --arg display_name "$target_display_name" \
          --arg project_name "$target_project_name" \
          --arg relative_path "$target_relative_path" \
          'map(select(.displayName != $display_name or .projectName != $project_name or .relativePath != $relative_path))' \
          "$JSON_CONFIG_FILE" > "$temp_file"; then

        # Check if the operation actually removed something
        local original_count="$project_count"
        local new_count=$(jq length "$temp_file")

        if [ "$new_count" -lt "$original_count" ]; then
            # Move the temporary file to replace the original
            if mv "$temp_file" "$JSON_CONFIG_FILE"; then
                print_color "$BRIGHT_GREEN" "✓ Project removed successfully"
                if [ "$BACKUP_JSON" = true ] && [ -n "$backup_file" ]; then
                    print_color "$BRIGHT_CYAN" "Backup created: $backup_file"
                fi
                print_color "$BRIGHT_WHITE" "Projects before: $original_count → Projects after: $new_count"
                return 0
            else
                print_error "Failed to update configuration file"
                rm -f "$temp_file"
                return 1
            fi
        else
            print_error "No matching project found to remove"
            print_color "$BRIGHT_YELLOW" "Searched for:"
            print_color "$BRIGHT_YELLOW" "  Display Name: $target_display_name"
            print_color "$BRIGHT_YELLOW" "  Folder Name: $target_project_name"
            print_color "$BRIGHT_YELLOW" "  Path: $target_relative_path"
            rm -f "$temp_file"
            if [ "$BACKUP_JSON" = true ] && [ -n "$backup_file" ]; then
                rm -f "$backup_file"  # Remove backup since no changes were made
            fi
            return 1
        fi
    else
        print_error "Failed to process JSON with jq"
        rm -f "$temp_file"
        if [ "$BACKUP_JSON" = true ] && [ -n "$backup_file" ]; then
            rm -f "$backup_file"
        fi
        return 1
    fi
}


# Callback function for displaying table rows
_display_table_row() {
    local counter="$1"
    local display_name="$2"
    local project_name="$3"
    local relative_path="$4"
    local startup_cmd="$5"
    local shutdown_cmd="$6"
    local highlight_number="$7"
    local current_mode="$8"

    # Truncate long values for better display
    local truncated_display_name=$(printf "%.15s" "$display_name")
    local truncated_project_name=$(printf "%.12s" "$project_name")
    local truncated_startup_cmd=$(printf "%.15s" "$startup_cmd")
    local truncated_shutdown_cmd=$(printf "%.15s" "$shutdown_cmd")

    # Add ellipsis if truncated
    [ ${#display_name} -gt 15 ] && truncated_display_name="${truncated_display_name}.."
    [ ${#project_name} -gt 12 ] && truncated_project_name="${truncated_project_name}.."
    [ ${#startup_cmd} -gt 15 ] && truncated_startup_cmd="${truncated_startup_cmd}.."
    [ ${#shutdown_cmd} -gt 15 ] && truncated_shutdown_cmd="${truncated_shutdown_cmd}.."

    # Check if this is the highlighted row
    if [ -n "$highlight_number" ] && [ "$counter" = "$highlight_number" ]; then
        # Set background color based on mode
        if [ "$current_mode" = "delete" ]; then
            local bg_color="\033[41m"  # Red background
            local text_color="\033[1;37m"  # Bright white text
        else
            local bg_color="\033[44m"  # Blue background
            local text_color="\033[1;37m"  # Bright white text
        fi

        # Display highlighted row with 5 columns
        printf "${bg_color}${text_color}  %-2s  %-15s  %-12s  %-15s  %-15s${NC}\n" "$counter" "$truncated_display_name" "$truncated_project_name" "$truncated_startup_cmd" "$truncated_shutdown_cmd"
    else
        # Display normal row with 5 columns
        printf "  ${BRIGHT_CYAN}%-2s${NC}  ${BRIGHT_WHITE}%-15s${NC}  ${DIM}%-12s${NC}  ${DIM}%-15s${NC}  ${DIM}%-15s${NC}\n" "$counter" "$truncated_display_name" "$truncated_project_name" "$truncated_startup_cmd" "$truncated_shutdown_cmd"
    fi
}

# Function to display configuration in table format
display_config_table() {
    local highlight_number="${1:-}"  # Optional row to highlight
    local current_mode="${2:-}"      # Optional mode for highlight color

    # Validate configuration
    if ! validate_json_config; then
        echo ""
        print_color "$BRIGHT_YELLOW" "Run the wizard (w) to create your first configuration."
        return 1
    fi

    # Get project count
    local project_count=$(get_project_count)
    if [ -z "$project_count" ] || [ "$project_count" -eq 0 ]; then
        print_color "$BRIGHT_YELLOW" "No projects configured."
        echo ""
        print_color "$BLUE" "Run the wizard (w) to add projects to your configuration."
        return 0
    fi

    print_color "$BRIGHT_CYAN" "Projects ($project_count configured)"
    echo ""

    # Display table header
    printf "  ${BRIGHT_WHITE}%-2s  %-15s  %-12s  %-15s  %-15s${NC}\n" "#" "Project Name" "Project Dir" "Startup Cmd" "Shutdown Cmd"
    printf "  ${DIM}%-2s  %-15s  %-12s  %-15s  %-15s${NC}\n" "─" "───────────────" "────────────" "───────────────" "────────────────"

    # Use utility function to iterate and display projects
    iterate_projects _display_table_row "$highlight_number" "$current_mode"
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
        echo ""
        echo -ne "${BRIGHT_YELLOW}Press Enter to continue...${NC}"
        read -r
        return 1
    fi

    echo ""
    print_color "$BRIGHT_CYAN" "Scanning projects directory: $projects_root"
    echo ""

    # Check if directory exists
    if [ ! -d "$projects_root" ]; then
        print_error "Projects directory does not exist: $projects_root"
        echo ""
        echo -ne "${BRIGHT_YELLOW}Press Enter to continue...${NC}"
        read -r
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

            # Check if this folder is already managed
            if is_folder_managed "$folder_name" "$projects_root"; then
                managed_status+=("managed")
            else
                managed_status+=("available")
            fi
        fi
    done < <(find "$projects_root" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)

    if [ ${#available_folders[@]} -eq 0 ]; then
        print_error "No folders found in projects directory: $projects_root"
        echo ""
        echo -ne "${BRIGHT_YELLOW}Press Enter to continue...${NC}"
        read -r
        return 1
    fi

    # Display table header
    printf "  ${BRIGHT_WHITE}%-2s  %-18s  %-8s${NC}\n" "#" "Folder Name" "Managed"
    printf "  ${DIM}%-2s  %-18s  %-8s${NC}\n" "─" "──────────────────" "───────"

    # Display all folders with their managed status
    for i in "${!available_folders[@]}"; do
        local counter=$((i + 1))
        local folder="${available_folders[i]}"
        local status="${managed_status[i]}"

        # Truncate long folder names
        local truncated_folder=$(printf "%.18s" "$folder")
        [ ${#folder} -gt 18 ] && truncated_folder="${truncated_folder}.."

        if [ "$status" = "managed" ]; then
            # Already managed - show in green
            printf "  ${DIM}%-2s  %-18s  ${BRIGHT_GREEN}%s${NC}\n" "$counter" "$truncated_folder" "$status"
        else
            # Available to add - show in yellow
            printf "  ${BRIGHT_CYAN}%-2s${NC}  ${BRIGHT_WHITE}%-18s${NC}  ${BRIGHT_YELLOW}%s${NC}\n" "$counter" "$truncated_folder" "$status"
        fi
    done

    echo ""
    print_color "$BRIGHT_YELLOW" "Select a folder to add (enter number), or press Enter to go back"
    echo -ne "${BRIGHT_CYAN}>${NC} "

    read -r folder_choice

    # Handle empty input (go back)
    if [ -z "$folder_choice" ]; then
        return 0
    fi

    # Validate choice is a number
    if ! [[ "$folder_choice" =~ ^[0-9]+$ ]]; then
        print_error "Invalid choice. Please enter a number."
        echo ""
        echo -ne "${BRIGHT_YELLOW}Press Enter to continue...${NC}"
        read -r
        return 1
    fi

    # Validate choice is in range
    if [ "$folder_choice" -lt 1 ] || [ "$folder_choice" -gt "${#available_folders[@]}" ]; then
        print_error "Invalid choice. Please select a number between 1 and ${#available_folders[@]}."
        echo ""
        echo -ne "${BRIGHT_YELLOW}Press Enter to continue...${NC}"
        read -r
        return 1
    fi

    # Get selected folder
    local selected_index=$((folder_choice - 1))
    local selected_folder="${available_folders[selected_index]}"
    local selected_status="${managed_status[selected_index]}"

    # Check if folder is already managed
    if [ "$selected_status" = "managed" ]; then
        print_error "Folder '$selected_folder' is already managed."
        echo ""
        echo -ne "${BRIGHT_YELLOW}Press Enter to continue...${NC}"
        read -r
        return 1
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

    echo ""
    echo -ne "${BRIGHT_YELLOW}Press Enter to continue...${NC}"
    read -r
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