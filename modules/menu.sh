#!/bin/bash

# ========================================
# Menu Interface Module
# ========================================
# This module handles the interactive menu system
# Usage: source modules/menu.sh

# Function to display menu and start project (for tmux session)
show_project_menu_tmux() {
    while true; do
        clear
        
        # Fancy header
        print_header "PROJECT STARTUP MENU"
        
        # Check if any projects are configured
        if [ ${#projects[@]} -eq 0 ]; then
            print_error "No projects configured."
            exit 1
        fi
        
        # Display numbered menu with project info
        echo ""
        for i in "${!projects[@]}"; do
            IFS=':' read -r display_name folder_name startup_cmd <<< "${projects[i]}"
            display_project_status "$i" "$display_name" "$folder_name" "$startup_cmd"
        done
        echo ""
        
        print_separator
        
        # Commands section with better formatting
        print_divider "COMMANDS"
        if [ ${#projects[@]} -eq 1 ]; then
            echo -e "${BRIGHT_GREEN}[1]${NC} start │ ${BRIGHT_RED}[k1]${NC} kill │ ${BRIGHT_YELLOW}[r]${NC} refresh │ ${BRIGHT_PURPLE}[w]${NC} wizard │ ${BRIGHT_PURPLE}[q]${NC} quit"
        else
            echo -e "${BRIGHT_GREEN}[1-${#projects[@]}]${NC} start │ ${BRIGHT_RED}[k1-k${#projects[@]}]${NC} kill │ ${BRIGHT_YELLOW}[r]${NC} refresh │ ${BRIGHT_PURPLE}[w]${NC} wizard │ ${BRIGHT_PURPLE}[q]${NC} quit"
        fi
        
        print_separator
        
        # Get user input with prompt (removed emoji)
        echo ""
        echo -ne "${BRIGHT_WHITE}Enter command${NC} ${BRIGHT_CYAN}>>${NC} "
        read -r choice
        
        # Handle user input
        handle_menu_choice "$choice"
    done
}

# Function to handle menu choices
handle_menu_choice() {
    local choice="$1"
    
    # Handle quit command
    if [[ $choice =~ ^[Qq]$ ]]; then
        handle_quit_command
        return
    fi
    
    # Handle refresh command
    if [[ $choice =~ ^[Rr]$ ]]; then
        handle_refresh_command
        return
    fi
    
    # Handle wizard command
    if [[ $choice =~ ^[Ww]$ ]]; then
        handle_wizard_command
        return
    fi
    
    # Handle kill commands (k1, k2, etc.)
    if [[ $choice =~ ^[Kk]([0-9]+)$ ]]; then
        local kill_choice="${BASH_REMATCH[1]}"
        handle_kill_command "$kill_choice"
        return
    fi
    
    # Handle start commands (1, 2, etc.)
    if [[ $choice =~ ^[0-9]+$ ]]; then
        handle_start_command "$choice"
        return
    fi
    
    # Invalid command
    print_error "Invalid command. Use numbers 1-${#projects[@]}, k1-k${#projects[@]}, r, w, or q"
    sleep 2
}

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

# Function to show help menu
show_help() {
    print_header "HELP - AVAILABLE COMMANDS"
    echo ""
    echo -e "${BRIGHT_GREEN}Start Commands:${NC}"
    echo -e "  ${BRIGHT_CYAN}1-${#projects[@]}${NC}    Start project by number"
    echo ""
    echo -e "${BRIGHT_RED}Kill Commands:${NC}"
    echo -e "  ${BRIGHT_CYAN}k1-k${#projects[@]}${NC}  Kill project by number"
    echo ""
    echo -e "${BRIGHT_YELLOW}Utility Commands:${NC}"
    echo -e "  ${BRIGHT_CYAN}r${NC}        Refresh project status"
    echo -e "  ${BRIGHT_CYAN}w${NC}        Re-run setup wizard"
    echo -e "  ${BRIGHT_CYAN}h${NC}        Show this help"
    echo -e "  ${BRIGHT_CYAN}q${NC}        Quit and close session"
    echo ""
    echo -ne "${BRIGHT_YELLOW}Press Enter to continue...${NC}"
    read -r
}

# Function to handle wizard re-run command
handle_wizard_command() {
    clear
    print_header "RE-RUN SETUP WIZARD"
    echo ""
    print_warning "This will DELETE your current project configuration!"
    echo -e "${BRIGHT_RED}Current config file:${NC} $JSON_CONFIG_FILE"
    echo ""
    print_info "All your current project settings will be lost."
    print_info "You'll need to reconfigure all projects from scratch."
    echo ""
    echo -ne "${BRIGHT_YELLOW}Are you sure you want to continue? ${BOLD}(y/N)${NC}: "
    read -r confirm
    
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        print_info "Wizard cancelled. Returning to menu..."
        sleep 2
        return
    fi
    
    echo ""
    print_step "Deleting current configuration..."
    
    # Delete the JSON config file
    if [ -f "$JSON_CONFIG_FILE" ]; then
        rm -f "$JSON_CONFIG_FILE"
        if [ $? -eq 0 ]; then
            print_success "Configuration file deleted successfully"
        else
            print_error "Failed to delete configuration file"
            sleep 3
            return
        fi
    else
        print_warning "Configuration file not found (already deleted?)"
    fi
    
    echo ""
    print_step "Starting setup wizard..."
    sleep 2
    
    # Clear the current projects array
    projects=()
    
    # Get the modules directory for wizard path
    local modules_dir="$(dirname "${BASH_SOURCE[0]}")"
       
    # Run the wizard
    if [ -f "$modules_dir/wizard.sh" ]; then
        (
            source "$modules_dir/wizard.sh"
            main
        )
        
        # Reload configuration after wizard
        echo ""
        print_step "Reloading configuration..."
        if load_projects_from_json; then
            print_success "New configuration loaded successfully!"
            echo -e "${BRIGHT_GREEN}Found ${#projects[@]} project(s) configured${NC}"
        else
            print_error "Failed to load new configuration"
            echo ""
            print_warning "The wizard may not have completed successfully."
            print_info "Please check the configuration or try running the wizard again."
        fi
    else
        print_error "Setup wizard not found at: $modules_dir/wizard.sh"
    fi
    
    echo ""
    echo -ne "${BRIGHT_YELLOW}Press Enter to return to menu...${NC}"
    read -r
}
