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
        
        # Display configuration directly in the menu
        display_config_table
        echo ""

        if [ "$current_mode" = "delete" ]; then
            echo -e "${BRIGHT_RED}●${NC} delete mode"
        elif [ "$current_mode" = "edit" ]; then
            echo -e "${BRIGHT_BLUE}●${NC} edit mode"
        else
            echo -e "${DIM}○${NC} no mode selected │ ${BRIGHT_PURPLE}[d]${NC} delete │ ${BRIGHT_PURPLE}[e]${NC} edit"
        fi
        echo ""

        echo -e "${BRIGHT_YELLOW}[b]${NC} back │ ${BRIGHT_YELLOW}[h]${NC} help"
        
        # Get user input with clean prompt
        echo ""
        if [ "$current_mode" = "delete" ]; then
            echo -ne "${DIM}Select project to ${BRIGHT_RED}delete${NC} ${DIM}(Enter to return)${NC} ${BRIGHT_CYAN}>${NC} "
        elif [ "$current_mode" = "edit" ]; then
            echo -ne "${DIM}Select project to ${BRIGHT_BLUE}edit${NC} ${DIM}(Enter to return)${NC} ${BRIGHT_CYAN}>${NC} "
        else
            echo -ne "${BRIGHT_CYAN}>${NC} "
        fi
        
        IFS= read -r -n1 -s choice

        # Handle Enter key in delete/edit mode - return to normal settings menu
        if [[ "$choice" == $'\n' || "$choice" == $'\r' || -z "$choice" ]] && ([ "$current_mode" = "delete" ] || [ "$current_mode" = "edit" ]); then
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
        
        # Handle navigation commands (disabled in edit mode)
        if [ "$current_mode" != "edit" ]; then
            case "${choice,,}" in
                "b")
                    echo -e "${BRIGHT_YELLOW}Returning to main menu${NC}"
                    sleep 0.5
                    break
                    ;;
                "h")
                    echo -e "${BRIGHT_YELLOW}Opening help${NC}"
                    sleep 0.5
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
                        
                        print_separator
                        
                        # Show confirmation prompt
                        local display_name=$(get_project_field "$choice" "displayName")
                        local project_name=$(get_project_field "$choice" "projectName")
                        
                        echo ""
                        if [ "$current_mode" = "delete" ]; then
                            echo -e "${BRIGHT_RED}⚠️  CONFIRM DELETION${NC}"
                            echo -e "Are you sure you want to ${BRIGHT_RED}DELETE${NC} project: ${BRIGHT_YELLOW}$display_name${NC} (${BRIGHT_CYAN}$project_name${NC})?"
                            echo -e "${BRIGHT_WHITE}Type [y] to confirm deletion, [n] to cancel${NC}"
                        else
                            echo -e "${BRIGHT_BLUE}📝 EDIT PROJECT${NC}"
                            echo -e "Edit project: ${BRIGHT_YELLOW}$display_name${NC} (${BRIGHT_CYAN}$project_name${NC})"
                            echo -e "${BRIGHT_WHITE}Type [y] to proceed with editing, [n] to cancel${NC}"
                        fi
                        
                        echo -ne "${BRIGHT_CYAN}>>${NC} "
                        read -r confirm_choice
                        
                        case "${confirm_choice,,}" in
                            "y"|"yes")
                                if [ "$current_mode" = "delete" ]; then
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
                                else
                                    echo -e "${BRIGHT_BLUE}✓ Starting project editor${NC}"
                                    # TODO: Add actual edit logic here
                                    echo -e "${BRIGHT_YELLOW}Project editor would launch (edit logic not implemented yet)${NC}"
                                fi
                                echo ""
                                echo -e "${BRIGHT_WHITE}Press Enter to continue...${NC}"
                                read -r
                                # Return to main settings menu after operation
                                current_mode=""
                                ;;
                            "n"|"no")
                                echo -e "${BRIGHT_YELLOW}Operation cancelled${NC}"
                                sleep 0.5
                                # Return to main settings menu after cancellation
                                current_mode=""
                                ;;
                            *)
                                echo -e "${BRIGHT_RED}Invalid choice. Operation cancelled${NC}"
                                sleep 0.5
                                # Return to main settings menu after invalid choice
                                current_mode=""
                                ;;
                        esac
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

    # Create a backup of the original file
    local backup_file="${JSON_CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    if ! cp "$JSON_CONFIG_FILE" "$backup_file"; then
        print_error "Failed to create backup file"
        return 1
    fi

    # Check if there's only one project - if so, remove the entire JSON file
    if [ "$project_count" -eq 1 ]; then
        # Remove the entire JSON file since this is the last project
        if rm "$JSON_CONFIG_FILE"; then
            print_color "$BRIGHT_GREEN" "✓ Last project removed - JSON configuration file deleted"
            print_color "$BRIGHT_CYAN" "Backup created: $backup_file"
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
                print_color "$BRIGHT_CYAN" "Backup created: $backup_file"
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
            rm -f "$backup_file"  # Remove backup since no changes were made
            return 1
        fi
    else
        print_error "Failed to process JSON with jq"
        rm -f "$temp_file"
        rm -f "$backup_file"
        return 1
    fi
}


# Callback function for displaying table rows
_display_table_row() {
    local counter="$1"
    local display_name="$2"
    local project_name="$3"
    local relative_path="$4"
    local highlight_number="$5"
    local current_mode="$6"

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

        # Display highlighted row
        printf "${bg_color}${text_color}  %-2s  %-20s  %-20s  %s${NC}\n" "$counter" "$display_name" "$project_name" "$relative_path"
    else
        # Display normal row
        printf "  ${BRIGHT_CYAN}%-2s${NC}  ${BRIGHT_WHITE}%-20s${NC}  ${DIM}%-20s${NC}  ${DIM}%s${NC}\n" "$counter" "$display_name" "$project_name" "$relative_path"
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

    # Use utility function to iterate and display projects
    iterate_projects _display_table_row "$highlight_number" "$current_mode"
}

# Function to show settings help
show_settings_help() {
    print_header "Settings Help"
    print_color "$BRIGHT_GREEN" "This menu displays your current project configuration."
    echo ""
    echo -e "${BRIGHT_YELLOW}Commands${NC}"
    echo -e "  ${BRIGHT_CYAN}d${NC}        delete mode"
    echo -e "  ${BRIGHT_CYAN}e${NC}        edit mode"
    echo -e "  ${BRIGHT_YELLOW}b${NC}        back to main menu"
    echo -e "  ${BRIGHT_YELLOW}h${NC}        show this help"
    echo ""

    echo -e "${BRIGHT_BLUE}Configuration${NC}"
    echo "  • Display Name - how the project appears in menus"
    echo "  • Folder Name - the actual directory name"
    echo "  • Path - the relative path to the project"
    echo ""
    echo -e "${BRIGHT_BLUE}Modes${NC}"
    echo "  • Delete Mode - select projects to remove"
    echo "  • Edit Mode - select projects to modify"
    echo "  • Press Enter while in a mode to return to Settings"
    echo ""
    echo -ne "${DIM}Press Enter to continue...${NC}"
    read -r
}