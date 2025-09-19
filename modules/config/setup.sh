#!/bin/bash

# ========================================
# Setup and Wizard Module
# ========================================
# This module handles setup and wizard functionality
# Usage: source modules/config/setup.sh

# Get the script directory to make paths relative to script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to check config and run wizard if needed
check_and_setup_config() {
    if [ ! -f "$JSON_CONFIG_FILE" ]; then
        print_header "SETUP REQUIRED"
        print_warning "Project configuration not found."
        print_info "Running setup wizard to configure your projects..."
        echo ""
        
        # Check if wizard exists
        if [ ! -f "$SCRIPT_DIR/../wizard.sh" ]; then
            print_error "wizard.sh not found in modules directory."
            print_error "Please ensure the setup wizard script is available."
            exit 1
        fi
        
        # Run the wizard
        show_loading "Launching setup wizard" 1
        (
            source "$SCRIPT_DIR/../wizard.sh"
            main
        )
        
        # Check if config was created AFTER running the wizard
        if [ ! -f "$JSON_CONFIG_FILE" ]; then
            print_error "Configuration was not created. Exiting."
            exit 1
        fi
        
        print_success "Configuration created successfully!"
        show_loading "Starting project manager" 1
        echo ""
    fi
}

# Function to run wizard when configuration is missing or invalid
run_setup_wizard() {
    # Check if wizard exists
    if [ ! -f "$SCRIPT_DIR/../wizard.sh" ]; then
        print_error "wizard.sh not found in modules directory."
        print_error "Please ensure the setup wizard script is available."
        exit 1
    fi
    
    # Run the wizard
    show_loading "Running setup wizard" 1
    (
        source "$SCRIPT_DIR/../wizard.sh"
        main
    )
}
