#!/bin/bash

# ========================================
# Menu Wizard Module
# ========================================
# This module handles wizard-related menu functionality
# Usage: source modules/menu/wizard.sh

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
    local modules_dir="$(dirname "${BASH_SOURCE[0]}")/.."
       
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
