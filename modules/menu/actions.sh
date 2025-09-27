#!/bin/bash

# ========================================
# Menu Actions Module
# ========================================
# This module handles menu action implementations
# Usage: source modules/menu/actions.sh

# Function to handle quit command
handle_quit_command() {
    show_loading "bye bye!" 1
    tmux kill-session
    exit 0
}


# Function to handle kill command
handle_kill_command() {
    local kill_choice="$1"
    
    if [ "$kill_choice" -ge 1 ] && [ "$kill_choice" -le "${#projects[@]}" ]; then
        local project_index=$((kill_choice - 1))
        IFS=':' read -r display_name folder_name startup_command shutdown_command <<< "${projects[$project_index]}"

        if is_project_running "$display_name"; then
            show_loading "Killing $display_name" 1
            if kill_project "$display_name" "$shutdown_command"; then
                print_success "$display_name stopped successfully"
            else
                print_error "Failed to stop $display_name"
            fi
        else
            print_warning "$display_name is not running"
        fi
        echo -ne "${BRIGHT_YELLOW}Press Enter to continue...${NC}"
        read -r
    else
        print_error "Invalid kill command. Use k1-k${#projects[@]}"
        sleep 2
    fi
}

# Function to handle start command
handle_start_command() {
    local choice="$1"
    
    if [ "$choice" -ge 1 ] && [ "$choice" -le "${#projects[@]}" ]; then
        local project_index=$((choice - 1))
        IFS=':' read -r display_name folder_name startup_command shutdown_command <<< "${projects[$project_index]}"
        
        # Check if project is already running
        if is_project_running "$display_name"; then
            echo ""
            print_warning "$display_name is already running!"
            print_info "Use 'k$choice' to kill it first, then start again."
            echo -ne "${BRIGHT_YELLOW}Press Enter to continue...${NC}"
            read -r
            return
        fi
        
        print_separator
        echo -e "${BRIGHT_WHITE}Selected project:${NC} ${BRIGHT_GREEN}$display_name${NC}"
        echo -e "${BRIGHT_WHITE}Project folder:${NC} ${BRIGHT_BLUE}$folder_name${NC}"
        echo -e "${BRIGHT_WHITE}Startup command:${NC} ${BRIGHT_YELLOW}$startup_command${NC}"
        print_separator
        
        start_project_in_tmux "$display_name" "$folder_name" "$startup_command"

        echo ""
        echo -ne "${BRIGHT_YELLOW}Press Enter to return to menu...${NC}"
        read -r
    else
        print_error "Please enter a number between 1 and ${#projects[@]}"
        echo -ne "${BRIGHT_YELLOW}Press Enter to continue...${NC}"
        read -r
    fi
}


# Function to handle settings command
handle_settings_command() {
    show_settings_menu
    # Reload configuration after returning from settings
    # This ensures the main menu reflects any changes made in settings
    reload_config
}

# Function to handle kill all command
handle_kill_all_command() {
    # Check if there are any running projects
    local running_projects
    running_projects=$(list_project_panes)

    if [[ -z "$running_projects" ]]; then
        print_warning "No projects are currently running"
        echo -ne "${BRIGHT_YELLOW}Press Enter to continue...${NC}"
        read -r
        return
    fi

    show_loading "Killing all running projects" 2
    kill_all_projects
    print_success "All projects stopped successfully"
    echo -ne "${BRIGHT_YELLOW}Press Enter to continue...${NC}"
    read -r
}

# Function to handle help command
handle_help_command() {
    show_help
}
