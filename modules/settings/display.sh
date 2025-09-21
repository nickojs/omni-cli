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
        
        # Fancy header
        print_header "SETTINGS MENU"
        
        # Display configuration directly in the menu
        display_config_table
        echo ""
        print_separator
        
        if [ "$current_mode" = "delete" ]; then
            echo -e "Mode: ${BRIGHT_RED}[✓] Delete${WHITE} | [ ] Edit${NC}"
        elif [ "$current_mode" = "edit" ]; then
            echo -e "Mode: [ ] Delete | ${BRIGHT_BLUE}[✓] Edit${NC}"
        else
            echo -e "${BRIGHT_WHITE}Mode: [ ] [d]elete | [ ] [e]dit${NC}"
        fi
        
        print_separator

        if [ "$current_mode" != "edit" ]; then
            echo -e "${BRIGHT_PURPLE}[d]${NC} delete │ ${BRIGHT_PURPLE}[e]${NC} edit │ ${BRIGHT_PURPLE}[b]${NC} back │ ${BRIGHT_PURPLE}[h]${NC} help │ ${BRIGHT_PURPLE}[q]${NC} quit"
        else
            echo -e "${BRIGHT_PURPLE}[b]${NC} back │ ${BRIGHT_PURPLE}[h]${NC} help │ ${BRIGHT_PURPLE}[q]${NC} quit"
        fi
        print_separator
        
        # Get user input with enhanced prompt based on current mode
        echo ""
        if [ "$current_mode" = "delete" ]; then
            echo -ne "${BRIGHT_WHITE}Select which project you want to ${BRIGHT_RED}delete${NC} ${BRIGHT_YELLOW}(or press Enter to return)${NC} ${BRIGHT_CYAN}>>${NC} "
        elif [ "$current_mode" = "edit" ]; then
            echo -ne "${BRIGHT_WHITE}Select which project you want to ${BRIGHT_BLUE}edit${NC} ${BRIGHT_YELLOW}(or press Enter to return)${NC} ${BRIGHT_CYAN}>>${NC} "
        else
            echo -ne "${BRIGHT_WHITE}Enter command${NC} ${BRIGHT_CYAN}>>${NC} "
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
                "q")
                    echo -e "${BRIGHT_YELLOW}Quitting${NC}"
                    sleep 0.5
                    exit 0
                    ;;
            esac
        fi
        
        # Handle project selection when in delete/edit mode
        if [ "$current_mode" = "delete" ] || [ "$current_mode" = "edit" ]; then
            # Check if input is a number
            if [[ $choice =~ ^[0-9]+$ ]]; then
                # Validate project selection
                if command -v jq >/dev/null 2>&1 && [ -f "$JSON_CONFIG_FILE" ] && [ -s "$JSON_CONFIG_FILE" ]; then
                    local project_count=$(jq length "$JSON_CONFIG_FILE")
                    
                    if [ "$choice" -ge 1 ] && [ "$choice" -le "$project_count" ]; then
                        # Clear screen and show highlighted selection
                        clear
                        print_header "SETTINGS MENU"
                        
                        # Display configuration with highlighted selection
                        display_config_table_with_highlight "$choice" "$current_mode"
                        
                        print_separator
                        
                        # Show confirmation prompt
                        local index=$((choice - 1))
                        local display_name=$(jq -r ".[$index].displayName" "$JSON_CONFIG_FILE")
                        local project_name=$(jq -r ".[$index].projectName" "$JSON_CONFIG_FILE")
                        
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
                                    local relative_path=$(jq -r ".[$index].relativePath" "$JSON_CONFIG_FILE")
                                    
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

    # Check if configuration file exists
    if [ ! -f "$JSON_CONFIG_FILE" ]; then
        print_error "Configuration file not found: $JSON_CONFIG_FILE"
        return 1
    fi

    # Check if jq is available
    if ! command -v jq >/dev/null 2>&1; then
        print_error "jq is required for JSON manipulation but is not installed"
        return 1
    fi

    # Check if JSON is valid
    if ! jq empty "$JSON_CONFIG_FILE" 2>/dev/null; then
        print_error "Invalid JSON format in configuration file"
        return 1
    fi

    # Create a backup of the original file
    local backup_file="${JSON_CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    if ! cp "$JSON_CONFIG_FILE" "$backup_file"; then
        print_error "Failed to create backup file"
        return 1
    fi

    # Check if there's only one project - if so, remove the entire JSON file
    if [ ${#projects[@]} -eq 1 ]; then
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
        local original_count=$(jq length "$JSON_CONFIG_FILE")
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

# Function to display configuration in table format with highlighted selection
display_config_table_with_highlight() {
    local highlight_number="$1"
    local current_mode="$2"
    
    # Check if configuration file exists
    if [ ! -f "$JSON_CONFIG_FILE" ]; then
        print_error "No configuration file found"
        return 1
    fi
    
    # Check if file is empty
    if [ ! -s "$JSON_CONFIG_FILE" ]; then
        print_error "Configuration file is empty"
        return 1
    fi
    
    # Check if jq is available for better JSON parsing
    if command -v jq >/dev/null 2>&1; then
        # Check if JSON is valid
        if ! jq empty "$JSON_CONFIG_FILE" 2>/dev/null; then
            print_error "Invalid JSON format in configuration file"
            return 1
        fi
        
        # Get number of projects
        local project_count=$(jq length "$JSON_CONFIG_FILE")
        
        if [ "$project_count" -eq 0 ]; then
            print_color "$BRIGHT_YELLOW" "No projects configured."
            return 0
        fi
        
        print_color "$BRIGHT_CYAN" "Current Projects ($project_count configured):"
        echo ""
        
        # Table header
        printf "%-4s %-20s %-20s %-30s\n" "#" "Display Name" "Folder Name" "Path"
        printf "%-4s %-20s %-20s %-30s\n" "---" "--------------------" "--------------------" "------------------------------"
        
        # Display each project in table format with highlighting
        local counter=1
        while [ $counter -le $project_count ]; do
            local index=$((counter - 1))
            
            # Extract project data
            local display_name=$(jq -r ".[$index].displayName" "$JSON_CONFIG_FILE")
            local project_name=$(jq -r ".[$index].projectName" "$JSON_CONFIG_FILE")
            local relative_path=$(jq -r ".[$index].relativePath" "$JSON_CONFIG_FILE")
            
            # Check if this is the highlighted row
            if [ "$counter" = "$highlight_number" ]; then
                # Set background color based on mode
                if [ "$current_mode" = "delete" ]; then
                    local bg_color="\033[41m"  # Light red background
                    local text_color="\033[1;37m"  # Bright white text
                else
                    local bg_color="\033[44m"  # Light blue background  
                    local text_color="\033[1;37m"  # Bright white text
                fi
                
                # Display highlighted row
                printf "${bg_color}${text_color}%-4s %-20s %-20s %-30s${NC}\n" "$counter" "$display_name" "$project_name" "$relative_path"
            else
                # Display normal row
                printf "${BRIGHT_WHITE}%-4s${NC} ${BRIGHT_YELLOW}%-20s${NC} ${BRIGHT_CYAN}%-20s${NC} ${BRIGHT_GREEN}%-30s${NC}\n" "$counter" "$display_name" "$project_name" "$relative_path"
            fi
            
            counter=$((counter + 1))
        done
    else
        print_color "$BRIGHT_YELLOW" "Install 'jq' for better configuration display"
        echo ""
        print_color "$BRIGHT_CYAN" "Raw configuration:"
        cat "$JSON_CONFIG_FILE"
    fi
}

# Function to display configuration in table format
display_config_table() {   
    # Check if configuration file exists
    if [ ! -f "$JSON_CONFIG_FILE" ]; then
        print_error "No configuration file found"
        echo ""
        print_color "$BRIGHT_YELLOW" "Run the wizard (w) to create your first configuration."
        return 1
    fi
    
    # Check if file is empty
    if [ ! -s "$JSON_CONFIG_FILE" ]; then
        print_error "Configuration file is empty"
        echo ""
        print_color "$BRIGHT_YELLOW" "Run the wizard (w) to create your first configuration."
        return 1
    fi
    
    # Check if jq is available for better JSON parsing
    if command -v jq >/dev/null 2>&1; then
        # Check if JSON is valid
        if ! jq empty "$JSON_CONFIG_FILE" 2>/dev/null; then
            print_error "Invalid JSON format in configuration file"
            return 1
        fi
        
        # Get number of projects
        local project_count=$(jq length "$JSON_CONFIG_FILE")
        
        if [ "$project_count" -eq 0 ]; then
            print_color "$BRIGHT_YELLOW" "No projects configured."
            echo ""
            print_color "$BLUE" "Run the wizard (w) to add projects to your configuration."
            return 0
        fi
        
        print_color "$BRIGHT_CYAN" "Current Projects ($project_count configured):"
        echo ""
        
        # Table header
        printf "%-4s %-20s %-20s %-30s\n" "#" "Display Name" "Folder Name" "Path"
        printf "%-4s %-20s %-20s %-30s\n" "---" "--------------------" "--------------------" "------------------------------"
        
        # Display each project in table format
        local counter=1
        while [ $counter -le $project_count ]; do
            local index=$((counter - 1))
            
            # Extract project data
            local display_name=$(jq -r ".[$index].displayName" "$JSON_CONFIG_FILE")
            local project_name=$(jq -r ".[$index].projectName" "$JSON_CONFIG_FILE")
            local relative_path=$(jq -r ".[$index].relativePath" "$JSON_CONFIG_FILE")
            
            # Display project info in table row format with colors
            printf "${BRIGHT_WHITE}%-4s${NC} ${BRIGHT_YELLOW}%-20s${NC} ${BRIGHT_CYAN}%-20s${NC} ${BRIGHT_GREEN}%-30s${NC}\n" "$counter" "$display_name" "$project_name" "$relative_path"
            
            counter=$((counter + 1))
        done
    else
        print_color "$BRIGHT_YELLOW" "Install 'jq' for better configuration display"
        echo ""
        print_color "$BRIGHT_CYAN" "Raw configuration:"
        cat "$JSON_CONFIG_FILE"
    fi
}

# Function to show settings help
show_settings_help() {
    print_header "SETTINGS HELP"
    echo ""
    print_color "$BRIGHT_GREEN" "This menu displays your current project configuration."
    echo ""
    echo -e "${BRIGHT_YELLOW}Commands:${NC}"
    echo -e "  ${BRIGHT_CYAN}d${NC}        Activate delete mode"
    echo -e "  ${BRIGHT_CYAN}e${NC}        Activate edit mode"
    echo -e "  ${BRIGHT_CYAN}b${NC}        Go back to main menu"
    echo -e "  ${BRIGHT_CYAN}h${NC}        Show this help"
    echo -e "  ${BRIGHT_CYAN}q${NC}        Quit and close session"
    echo ""

    echo -e "${BRIGHT_BLUE}The configuration shows:${NC}"
    echo "  • Display Name - How the project appears in menus"
    echo "  • Folder Name - The actual directory name"
    echo "  • Path - The relative path to the project"
    echo ""
    echo -e "${BRIGHT_BLUE}Modes:${NC}"
    echo "  • Delete Mode - Select projects to remove from configuration"
    echo "  • Edit Mode - Select projects to modify their settings"
    echo "  • Press Enter while in a mode to return to Settings menu"
    echo "  • Navigation commands (b/h/q) are disabled in Edit Mode"
    echo ""
    echo -ne "${BRIGHT_YELLOW}Press Enter to continue...${NC}"
    read -r
}