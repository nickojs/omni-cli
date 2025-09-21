#!/bin/bash

# ========================================
# Configuration Loader Module
# ========================================
# This module handles the main configuration loading logic
# Usage: source modules/config/loader.sh

# Load the project configuration
load_config() {
    if ! load_projects_from_json; then
        print_error "Could not load $JSON_CONFIG_FILE"
        echo ""
        print_color "$BRIGHT_YELLOW" "Would you like to run the setup wizard to create the configuration? ${BOLD}(y/n): "
        read -r run_wizard
        
        if [[ $run_wizard =~ ^[Yy]$ ]]; then
            # Run the wizard
            check_and_setup_config
            
            # Try loading again after wizard
            if ! load_projects_from_json; then
                print_error "Configuration was not created properly. Exiting."
                exit 1
            fi
        else
            print_error "Cannot proceed without project configuration. Exiting."
            exit 1
        fi
    fi
    
    # Verify we have projects
    if [ ${#projects[@]} -eq 0 ]; then
        print_warning "No projects found in configuration."
        echo ""
        print_color "$BRIGHT_YELLOW" "Would you like to run the setup wizard to add projects? ${BOLD}(y/n)${NC}: "
        read -r run_wizard
        
        if [[ $run_wizard =~ ^[Yy]$ ]]; then
            # Run the wizard
            check_and_setup_config
            
            # Try loading again
            if ! load_projects_from_json || [ ${#projects[@]} -eq 0 ]; then
                print_error "No projects were configured. Exiting."
                exit 1
            fi
        else
            print_error "Cannot proceed without projects. Exiting."
            exit 1
        fi
    fi
}
