#!/bin/bash

# ========================================
# Configuration Management Module
# ========================================
# This module handles JSON parsing and configuration management
# Usage: source modules/config.sh

# Get the script directory to make paths relative to script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Global projects array
declare -g -a projects=()

# Function to load projects from JSON config
load_projects_from_json() {
    local json_file="$JSON_CONFIG_FILE"
    
    if [ ! -f "$json_file" ]; then
        return 1
    fi
    
    # Parse JSON and create the projects array
    projects=()
    
    # Read each project object from JSON
    while IFS= read -r line; do
        # Skip lines that don't contain project objects
        if [[ ! "$line" =~ \"displayName\" ]]; then
            continue
        fi
        
        # Extract values using basic string manipulation
        local display_name=$(echo "$line" | grep -o '"displayName": *"[^"]*"' | sed 's/"displayName": *"//' | sed 's/".*//')
        local relative_path=$(echo "$line" | grep -o '"relativePath": *"[^"]*"' | sed 's/"relativePath": *"//' | sed 's/".*//')
        local startup_cmd=$(echo "$line" | grep -o '"startupCmd": *"[^"]*"' | sed 's/"startupCmd": *"//' | sed 's/".*//')
        
        # Add to projects array in the original format (using relativePath as folder_name)
        if [ -n "$display_name" ] && [ -n "$relative_path" ] && [ -n "$startup_cmd" ]; then
            projects+=("$display_name:$relative_path:$startup_cmd")
        fi
    done < <(cat "$json_file" | tr -d '\n' | sed 's/},/},\n/g' | grep -o '{[^}]*}')
    
    return 0
}

# Function to check config and run wizard if needed
check_and_setup_config() {
    if [ ! -f "$JSON_CONFIG_FILE" ]; then
        print_header "SETUP REQUIRED"
        print_warning "Project configuration not found."
        print_info "Running setup wizard to configure your projects..."
        echo ""
        
        # Check if wizard exists
        if [ ! -f "$SCRIPT_DIR/wizard.sh" ]; then
            print_error "wizard.sh not found in modules directory."
            print_error "Please ensure the setup wizard script is available."
            exit 1
        fi
        
        # Run the wizard
        show_loading "Launching setup wizard" 1
        (
            source "$SCRIPT_DIR/wizard.sh"
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

# Load the project configuration
load_config() {
    if ! load_projects_from_json; then
        print_error "Could not load $JSON_CONFIG_FILE"
        echo ""
        print_color "$BRIGHT_YELLOW" "Would you like to run the setup wizard to create the configuration? ${BOLD}(y/n): "
        read -r run_wizard
        
        if [[ $run_wizard =~ ^[Yy]$ ]]; then
            # Check if wizard exists
            if [ ! -f "$SCRIPT_DIR/wizard.sh" ]; then
                print_error "wizard.sh not found in modules directory."
                print_error "Please ensure the setup wizard script is available."
                exit 1
            fi
            
            # Run the wizard
            show_loading "Running setup wizard" 1
            (
                source "$SCRIPT_DIR/wizard.sh"
                main
            )
            
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
            # Check if wizard exists
            if [ ! -f "$SCRIPT_DIR/wizard.sh" ]; then
                print_error "wizard.sh not found in modules directory."
                exit 1
            fi
            
            # Run the wizard
            show_loading "Running setup wizard" 1
            (
                source "$SCRIPT_DIR/wizard.sh"
                main
            )
            
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

# Function to validate configuration format
validate_config() {
    local json_file="$JSON_CONFIG_FILE"
    
    if [ ! -f "$json_file" ]; then
        return 1
    fi
    
    # Basic JSON validation - check for required fields
    if ! grep -q '"displayName"' "$json_file" || \
       ! grep -q '"projectName"' "$json_file" || \
       ! grep -q '"startupCmd"' "$json_file"; then
        return 1
    fi
    
    return 0
}

# Function to reload configuration (used after wizard re-run)
reload_config() {
    if load_projects_from_json; then
        return 0
    else
        return 1
    fi
}
