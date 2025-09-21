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

# Function to handle refresh command
handle_refresh_command() {
    show_loading "Refreshing status" 1
}

# Function to handle kill command
handle_kill_command() {
    local kill_choice="$1"
    
    if [ "$kill_choice" -ge 1 ] && [ "$kill_choice" -le "${#projects[@]}" ]; then
        local project_index=$((kill_choice - 1))
        IFS=':' read -r display_name folder_name startup_command <<< "${projects[$project_index]}"
        
        if is_project_running "$display_name"; then
            show_loading "Killing $display_name" 1
            if kill_project "$display_name"; then
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
        IFS=':' read -r display_name folder_name startup_command <<< "${projects[$project_index]}"
        
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
        show_loading "Returning to menu" 2
    else
        print_error "Please enter a number between 1 and ${#projects[@]}"
        sleep 2
    fi
}

# Function to handle fetch command
handle_fetch_command() {
    clear
    fetch_project_menu
}

# Function to handle settings command
handle_settings_command() {
    show_settings_menu
    # Reload configuration after returning from settings
    # This ensures the main menu reflects any changes made in settings
    reload_config
}

# Function to handle help command
handle_help_command() {
    show_help
}
